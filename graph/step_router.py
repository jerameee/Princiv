"""
step_router.py — LangGraph node for SSA sequential evaluation traversal.

The node reads the current evaluation state (active_step + answer), queries
Neo4j for the appropriate IF_YES_GO_TO / IF_NO_GO_TO edge, and returns updated
state with the next step or final disposition.

Usage (LangGraph):
    from graph.step_router import build_step_router

    router = build_step_router(driver)          # neo4j.Driver instance
    graph  = StateGraph(EvaluationState)
    graph.add_node("step_router", router)
"""

from __future__ import annotations

from typing import Literal, TypedDict

import neo4j


# ---------------------------------------------------------------------------
# State schema
# ---------------------------------------------------------------------------

class EvaluationState(TypedDict, total=False):
    """Shared LangGraph state for the SSA sequential evaluation workflow."""

    active_step: str
    """Current EvaluationStep node id, e.g. 'step_1_sga'.
    Set to None once a terminal outcome is reached."""

    answer: Literal["yes", "no"]
    """Claimant/ALJ answer to the current step's question."""

    step_name: str
    """Human-readable name of the current step."""

    step_question: str
    """The question posed at the current step."""

    disposition: str | None
    """'disabled' | 'not_disabled' | None (evaluation still in progress)."""

    outcome_label: str
    """Short outcome label from the traversed edge (e.g. 'meets_or_equals_listing')."""

    is_terminal: bool
    """True once a DispositionOutcome node has been reached."""


# ---------------------------------------------------------------------------
# Cypher — traverse one edge from the current step
# ---------------------------------------------------------------------------

_TRAVERSE_QUERY = """
MATCH (current {{id: $step_id}})-[r:{rel_type}]->(next)
RETURN
    next.id        AS next_id,
    next.name      AS next_name,
    r.outcome      AS outcome_label,
    r.disposition  AS disposition,
    labels(next)   AS target_labels
"""


def _rel_type(answer: str) -> str:
    return "IF_YES_GO_TO" if answer.lower() == "yes" else "IF_NO_GO_TO"


# ---------------------------------------------------------------------------
# Public builder — returns the LangGraph-compatible node function
# ---------------------------------------------------------------------------

def build_step_router(driver: neo4j.Driver) -> callable:
    """
    Returns a LangGraph node function bound to the given Neo4j driver.

    The returned function accepts an EvaluationState dict and returns a
    partial dict with only the keys that changed — compatible with
    LangGraph's state-merge semantics.
    """

    def step_router(state: EvaluationState) -> dict:
        step_id = state.get("active_step")
        answer  = state.get("answer", "").lower()

        if not step_id:
            raise ValueError("step_router: 'active_step' missing from state")
        if answer not in ("yes", "no"):
            raise ValueError(f"step_router: 'answer' must be 'yes' or 'no', got {answer!r}")

        rel = _rel_type(answer)
        query = _TRAVERSE_QUERY.format(rel_type=rel)

        with driver.session() as session:
            record = session.run(query, step_id=step_id).single()

        if record is None:
            raise LookupError(
                f"step_router: no {rel} edge found from step '{step_id}'. "
                "Verify the evaluation graph is loaded."
            )

        target_labels: list[str] = record["target_labels"]
        is_terminal = "EvaluationOutcome" in target_labels

        updates: dict = {
            "outcome_label": record["outcome_label"],
            "disposition":   record["disposition"],
            "is_terminal":   is_terminal,
        }

        if is_terminal:
            updates["active_step"]    = None
            updates["step_name"]      = record["next_name"]
            updates["step_question"]  = None
        else:
            updates["active_step"]    = record["next_id"]
            updates["step_name"]      = record["next_name"]

        return updates

    return step_router
