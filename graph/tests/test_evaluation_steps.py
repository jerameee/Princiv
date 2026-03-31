"""
test_evaluation_steps.py — Acceptance-criteria test suite for Task 1.4.

Covers three acceptance criteria:

  AC1  MATCH (e:EvaluationStep) RETURN count(e) returns 5
  AC2  Full five-step path is traversable in a single MATCH query
       using IF_YES_GO_TO / IF_NO_GO_TO
  AC3  step_router LangGraph node can traverse the graph to determine
       next active_step

Integration tests (AC1, AC2) require a live Neo4j instance loaded with
load_evaluation_steps.cypher.  They are automatically skipped when Neo4j
is unavailable so CI remains green before the database is provisioned.

Unit tests (AC3) use a mock driver and always run.

Environment variables (all optional, defaults match Neo4j Desktop defaults):
  NEO4J_URI      bolt://localhost:7687
  NEO4J_USER     neo4j
  NEO4J_PASSWORD password
"""

from __future__ import annotations

import os
import sys
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest

# Make the graph package importable from the project root
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from graph.step_router import EvaluationState, build_step_router

# ---------------------------------------------------------------------------
# Neo4j connection fixture (skipped when unavailable)
# ---------------------------------------------------------------------------

NEO4J_URI  = os.getenv("NEO4J_URI",      "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER",     "neo4j")
NEO4J_PASS = os.getenv("NEO4J_PASSWORD", "password")


def _neo4j_available() -> bool:
    try:
        import neo4j
        d = neo4j.GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))
        d.verify_connectivity()
        d.close()
        return True
    except Exception:
        return False


neo4j_required = pytest.mark.skipif(
    not _neo4j_available(),
    reason="Neo4j not reachable — start the database to run integration tests",
)


@pytest.fixture(scope="module")
def neo4j_driver():
    import neo4j
    driver = neo4j.GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASS))
    yield driver
    driver.close()


# ---------------------------------------------------------------------------
# AC1 — EvaluationStep count == 5
# ---------------------------------------------------------------------------

class TestAC1_StepCount:
    @neo4j_required
    def test_exactly_five_evaluation_steps(self, neo4j_driver):
        """MATCH (e:EvaluationStep) RETURN count(e) must return 5."""
        with neo4j_driver.session() as session:
            result = session.run("MATCH (e:EvaluationStep) RETURN count(e) AS cnt")
            count = result.single()["cnt"]
        assert count == 5, f"Expected 5 EvaluationStep nodes, got {count}"

    @neo4j_required
    def test_required_step_ids_present(self, neo4j_driver):
        """All five canonical step IDs must exist in the graph."""
        expected = {
            "step_1_sga",
            "step_2_severity",
            "step_3_listings",
            "step_4_prw",
            "step_5_other_work",
        }
        with neo4j_driver.session() as session:
            result = session.run("MATCH (e:EvaluationStep) RETURN e.id AS id")
            found = {r["id"] for r in result}
        assert found == expected, f"Missing step IDs: {expected - found}"

    @neo4j_required
    def test_all_steps_have_required_properties(self, neo4j_driver):
        """Every EvaluationStep must have step_number, name, question, burden_of_proof."""
        required_props = ["step_number", "name", "question", "burden_of_proof"]
        with neo4j_driver.session() as session:
            result = session.run(
                """
                MATCH (e:EvaluationStep)
                RETURN e.id          AS id,
                       e.step_number AS step_number,
                       e.name        AS name,
                       e.question    AS question,
                       e.burden_of_proof AS burden_of_proof
                """
            )
            rows = result.data()

        assert len(rows) == 5
        for row in rows:
            for prop in required_props:
                assert row[prop] is not None, (
                    f"Step '{row['id']}' is missing required property '{prop}'"
                )


# ---------------------------------------------------------------------------
# AC2 — Full five-step path traversable in a single MATCH query
# ---------------------------------------------------------------------------

class TestAC2_PathTraversal:
    @neo4j_required
    def test_full_path_traversable_to_disabled(self, neo4j_driver):
        """
        The claimant-favored path (no SGA → severe MDI → no listing →
        no PRW → no other work → disabled) must be traversable in one query.
        """
        query = """
        MATCH path = (s1:EvaluationStep {id: 'step_1_sga'})
                     -[:IF_NO_GO_TO]->(s2:EvaluationStep)
                     -[:IF_YES_GO_TO]->(s3:EvaluationStep)
                     -[:IF_NO_GO_TO]->(s4:EvaluationStep)
                     -[:IF_NO_GO_TO]->(s5:EvaluationStep)
                     -[:IF_NO_GO_TO]->(outcome:EvaluationOutcome)
        RETURN
            [n IN nodes(path) | coalesce(n.name, n.result)] AS path_names,
            outcome.result AS final_disposition
        """
        with neo4j_driver.session() as session:
            result = session.run(query)
            row = result.single()

        assert row is not None, "Five-step path returned no results — graph may not be loaded"
        assert row["final_disposition"] == "disabled", (
            f"Expected 'disabled', got '{row['final_disposition']}'"
        )
        assert len(row["path_names"]) == 6, (
            f"Expected 6 nodes in path (5 steps + outcome), got {len(row['path_names'])}"
        )

    @neo4j_required
    def test_all_steps_have_both_branch_edges(self, neo4j_driver):
        """Every EvaluationStep must have exactly one IF_YES_GO_TO and one IF_NO_GO_TO edge."""
        query = """
        MATCH (e:EvaluationStep)-[r:IF_YES_GO_TO|IF_NO_GO_TO]->()
        RETURN e.id AS step_id, type(r) AS rel_type, count(r) AS cnt
        """
        with neo4j_driver.session() as session:
            rows = session.run(query).data()

        by_step: dict[str, set] = {}
        for row in rows:
            by_step.setdefault(row["step_id"], set()).add(row["rel_type"])

        assert len(by_step) == 5, f"Expected 5 steps with edges, found {len(by_step)}"
        for step_id, rel_types in by_step.items():
            assert "IF_YES_GO_TO" in rel_types, f"Step '{step_id}' missing IF_YES_GO_TO"
            assert "IF_NO_GO_TO"  in rel_types, f"Step '{step_id}' missing IF_NO_GO_TO"

    @neo4j_required
    def test_step3_yes_leads_to_disabled(self, neo4j_driver):
        """Step 3 IF_YES_GO_TO must terminate at outcome_disabled (Listing match)."""
        query = """
        MATCH (s3:EvaluationStep {id: 'step_3_listings'})
              -[:IF_YES_GO_TO]->(outcome:EvaluationOutcome)
        RETURN outcome.result AS disposition
        """
        with neo4j_driver.session() as session:
            row = session.single(query)

        assert row is not None
        assert row["disposition"] == "disabled"

    @neo4j_required
    def test_step5_exhausts_to_both_outcomes(self, neo4j_driver):
        """Step 5 must reach not_disabled on YES and disabled on NO."""
        query = """
        MATCH (s5:EvaluationStep {id: 'step_5_other_work'})-[r]->(o:EvaluationOutcome)
        RETURN type(r) AS branch, o.result AS disposition
        ORDER BY type(r)
        """
        with neo4j_driver.session() as session:
            rows = {r["branch"]: r["disposition"] for r in session.run(query)}

        assert rows.get("IF_YES_GO_TO") == "not_disabled"
        assert rows.get("IF_NO_GO_TO")  == "disabled"


# ---------------------------------------------------------------------------
# AC3 — step_router LangGraph node traverses the graph correctly
# (unit tests — always run; mock driver, no live Neo4j required)
# ---------------------------------------------------------------------------

def _make_driver_mock(next_id, next_name, outcome_label, disposition, target_labels):
    """Helper: returns a mock neo4j.Driver whose session().run().single() returns a record."""
    record = MagicMock()
    record.__getitem__ = lambda self, key: {
        "next_id":       next_id,
        "next_name":     next_name,
        "outcome_label": outcome_label,
        "disposition":   disposition,
        "target_labels": target_labels,
    }[key]

    session_mock = MagicMock()
    session_mock.run.return_value.single.return_value = record
    session_mock.__enter__ = lambda s: session_mock
    session_mock.__exit__  = MagicMock(return_value=False)

    driver_mock = MagicMock()
    driver_mock.session.return_value = session_mock
    return driver_mock


class TestAC3_StepRouter:
    def test_step1_no_routes_to_step2(self):
        """IF_NO from Step 1 should advance to step_2_severity."""
        driver = _make_driver_mock(
            next_id="step_2_severity",
            next_name="Severe Medically Determinable Impairment",
            outcome_label="not_performing_sga",
            disposition=None,
            target_labels=["EvaluationStep"],
        )
        router = build_step_router(driver)
        state: EvaluationState = {"active_step": "step_1_sga", "answer": "no"}

        updates = router(state)

        assert updates["active_step"]  == "step_2_severity"
        assert updates["is_terminal"]  is False
        assert updates["disposition"]  is None
        assert updates["outcome_label"] == "not_performing_sga"

    def test_step3_yes_routes_to_disabled_outcome(self):
        """IF_YES from Step 3 must reach a terminal EvaluationOutcome with disposition=disabled."""
        driver = _make_driver_mock(
            next_id="outcome_disabled",
            next_name="Disabled",
            outcome_label="meets_or_equals_listing",
            disposition="disabled",
            target_labels=["EvaluationOutcome"],
        )
        router = build_step_router(driver)
        state: EvaluationState = {"active_step": "step_3_listings", "answer": "yes"}

        updates = router(state)

        assert updates["is_terminal"] is True
        assert updates["disposition"] == "disabled"
        assert updates["active_step"] is None

    def test_step5_no_routes_to_disabled_outcome(self):
        """IF_NO from Step 5 must reach a terminal EvaluationOutcome with disposition=disabled."""
        driver = _make_driver_mock(
            next_id="outcome_disabled",
            next_name="Disabled",
            outcome_label="no_other_work_in_national_economy",
            disposition="disabled",
            target_labels=["EvaluationOutcome"],
        )
        router = build_step_router(driver)
        state: EvaluationState = {"active_step": "step_5_other_work", "answer": "no"}

        updates = router(state)

        assert updates["is_terminal"] is True
        assert updates["disposition"] == "disabled"

    def test_step5_yes_routes_to_not_disabled_outcome(self):
        """IF_YES from Step 5 must reach a terminal EvaluationOutcome with disposition=not_disabled."""
        driver = _make_driver_mock(
            next_id="outcome_not_disabled",
            next_name="Not Disabled",
            outcome_label="other_work_exists_in_national_economy",
            disposition="not_disabled",
            target_labels=["EvaluationOutcome"],
        )
        router = build_step_router(driver)
        state: EvaluationState = {"active_step": "step_5_other_work", "answer": "yes"}

        updates = router(state)

        assert updates["is_terminal"] is True
        assert updates["disposition"] == "not_disabled"

    def test_full_path_traversal_via_router(self):
        """
        Simulate a full claimant-favored path through all five steps using
        the step_router. Each call returns the next step; final call returns
        the disabled outcome.
        """
        # (step_id, answer) → next_id, outcome, disposition, target_labels
        traversal = [
            ("step_1_sga",        "no",  "step_2_severity",      "not_performing_sga",                   None,          ["EvaluationStep"]),
            ("step_2_severity",   "yes", "step_3_listings",      "severe_impairment_established",         None,          ["EvaluationStep"]),
            ("step_3_listings",   "no",  "step_4_prw",           "does_not_meet_listing",                 None,          ["EvaluationStep"]),
            ("step_4_prw",        "no",  "step_5_other_work",    "cannot_perform_past_relevant_work",     None,          ["EvaluationStep"]),
            ("step_5_other_work", "no",  "outcome_disabled",     "no_other_work_in_national_economy",     "disabled",    ["EvaluationOutcome"]),
        ]

        visited_steps = []
        active_step   = "step_1_sga"

        for (step_id, answer, next_id, outcome_label, disposition, labels) in traversal:
            assert active_step == step_id, f"Expected step '{step_id}', was at '{active_step}'"

            driver = _make_driver_mock(next_id, next_id, outcome_label, disposition, labels)
            router = build_step_router(driver)

            state: EvaluationState = {"active_step": active_step, "answer": answer}
            updates = router(state)

            visited_steps.append(step_id)
            active_step = updates["active_step"]  # None on terminal

        assert len(visited_steps) == 5, f"Expected 5 steps traversed, got {len(visited_steps)}"
        assert active_step is None, "active_step should be None after reaching terminal outcome"

    def test_invalid_answer_raises(self):
        """Router must raise ValueError for an answer other than 'yes' or 'no'."""
        driver = MagicMock()
        router = build_step_router(driver)
        with pytest.raises(ValueError, match="answer"):
            router({"active_step": "step_1_sga", "answer": "maybe"})

    def test_missing_active_step_raises(self):
        """Router must raise ValueError when active_step is absent from state."""
        driver = MagicMock()
        router = build_step_router(driver)
        with pytest.raises(ValueError, match="active_step"):
            router({"answer": "yes"})

    def test_missing_edge_raises_lookup_error(self):
        """Router must raise LookupError when Neo4j returns no record for the traversal."""
        session_mock = MagicMock()
        session_mock.run.return_value.single.return_value = None
        session_mock.__enter__ = lambda s: session_mock
        session_mock.__exit__  = MagicMock(return_value=False)

        driver_mock = MagicMock()
        driver_mock.session.return_value = session_mock

        router = build_step_router(driver_mock)
        with pytest.raises(LookupError, match="no IF_NO_GO_TO edge"):
            router({"active_step": "step_1_sga", "answer": "no"})
