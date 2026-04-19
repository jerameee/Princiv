"""
test_grid_rules_and_occupations.py
Acceptance criteria tests for Task 1.6: Grid Rules and DOT Occupations

Requires Neo4j running with seed data loaded:
  schema.cypher
  load_evaluation_steps.cypher
  load_mvp_regulatory_content.cypher
  load_grid_rules_and_occupations.cypher   ← Task 1.6

Auto-skips if Neo4j is unreachable or the neo4j driver is not installed.

Environment variables:
  NEO4J_URI      — default: bolt://localhost:7687
  NEO4J_USER     — default: neo4j
  NEO4J_PASSWORD — default: password

Acceptance criteria:
  AC1  Grid rule lookup Cypher (given rfc_level + age_category + education +
       work_experience) returns the correct decision and rule_number with 100%
       accuracy against Appendix 2.

  AC2  Step 5 other-work query returns at least 3 compatible occupations for
       a sedentary RFC profile.
"""

import os
import pytest

try:
    from neo4j import GraphDatabase
    NEO4J_AVAILABLE = True
except ImportError:
    NEO4J_AVAILABLE = False

from graph.cypher_templates import GRID_RULE_LOOKUP, STEP5_OTHER_WORK


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def driver():
    if not NEO4J_AVAILABLE:
        pytest.skip("neo4j driver not installed")

    uri      = os.getenv("NEO4J_URI",      "bolt://localhost:7687")
    user     = os.getenv("NEO4J_USER",     "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password")

    try:
        drv = GraphDatabase.driver(uri, auth=(user, password))
        drv.verify_connectivity()
        return drv
    except Exception:
        pytest.skip("Neo4j not reachable — skipping grid rules / occupations tests")


@pytest.fixture(scope="module")
def session(driver):
    with driver.session() as s:
        yield s


# ---------------------------------------------------------------------------
# Node count sanity checks
# ---------------------------------------------------------------------------

class TestNodeCounts:

    def test_grid_rule_count_at_least_26(self, session):
        result = session.run("MATCH (gr:GridRule) RETURN count(gr) AS n")
        assert result.single()["n"] >= 26

    def test_dot_occupation_count_is_28(self, session):
        result = session.run("MATCH (occ:DOTOccupation) RETURN count(occ) AS n")
        assert result.single()["n"] == 28

    def test_sedentary_occupations_exist(self, session):
        result = session.run(
            "MATCH (occ:DOTOccupation {physical_demands: 'sedentary'}) RETURN count(occ) AS n"
        )
        assert result.single()["n"] >= 3

    def test_light_occupations_exist(self, session):
        result = session.run(
            "MATCH (occ:DOTOccupation {physical_demands: 'light'}) RETURN count(occ) AS n"
        )
        assert result.single()["n"] >= 3

    def test_medium_occupations_exist(self, session):
        result = session.run(
            "MATCH (occ:DOTOccupation {physical_demands: 'medium'}) RETURN count(occ) AS n"
        )
        assert result.single()["n"] >= 3

    def test_unskilled_occupations_svp1_and_2_exist(self, session):
        result = session.run(
            "MATCH (occ:DOTOccupation) WHERE occ.svp <= 2 RETURN count(occ) AS n"
        )
        assert result.single()["n"] >= 10

    def test_semi_skilled_occupations_svp3_and_4_exist(self, session):
        result = session.run(
            "MATCH (occ:DOTOccupation) WHERE occ.svp IN [3, 4] RETURN count(occ) AS n"
        )
        assert result.single()["n"] >= 5

    def test_results_in_decision_edges_exist(self, session):
        result = session.run(
            "MATCH ()-[:RESULTS_IN_DECISION]->() RETURN count(*) AS n"
        )
        assert result.single()["n"] >= 25

    def test_compatible_with_jobs_edges_exist(self, session):
        result = session.run(
            "MATCH (:WorkLevel)-[:COMPATIBLE_WITH_JOBS]->(:DOTOccupation) RETURN count(*) AS n"
        )
        assert result.single()["n"] >= 9  # at minimum wl_sedentary → 9 sedentary jobs

    def test_governs_edges_from_task16_exist(self, session):
        result = session.run("""
            MATCH (wl:WorkLevel)-[:GOVERNS]->(gr:GridRule)
            WHERE gr.id IN ['gr_201_01','gr_202_01','gr_203_01']
            RETURN count(*) AS n
        """)
        assert result.single()["n"] == 3

    def test_dot_occupation_nodes_carry_occupation_label(self, session):
        result = session.run(
            "MATCH (occ:Occupation) WHERE occ:DOTOccupation RETURN count(occ) AS n"
        )
        assert result.single()["n"] == 28


# ---------------------------------------------------------------------------
# AC1 – Grid rule lookup (100% accuracy against Appendix 2)
# ---------------------------------------------------------------------------

class TestAC1GridRuleLookup:
    """
    Each test asserts that GRID_RULE_LOOKUP returns a single row whose
    rule_number and decision exactly match the published Appendix 2 table.
    """

    def _lookup(self, session, rfc_level, age_category, education, work_experience):
        rows = session.run(
            GRID_RULE_LOOKUP,
            rfc_level=rfc_level,
            age_category=age_category,
            education=education,
            work_experience=work_experience,
        ).data()
        return rows

    # Table 1 – Sedentary, advanced age (55+)

    def test_201_01_sedentary_advanced_limited_unskilled_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.01"
        assert rows[0]["decision"] == "disabled"

    def test_201_02_sedentary_advanced_limited_nontransferable_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "limited_or_less", "skilled_nontransferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.02"
        assert rows[0]["decision"] == "disabled"

    def test_201_03_sedentary_advanced_limited_transferable_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "limited_or_less", "skilled_transferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.03"
        assert rows[0]["decision"] == "not_disabled"

    def test_201_04_sedentary_advanced_hs_no_entry_unskilled_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "high_school_no_direct_entry", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.04"
        assert rows[0]["decision"] == "disabled"

    def test_201_06_sedentary_advanced_hs_no_entry_transferable_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "high_school_no_direct_entry", "skilled_transferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.06"
        assert rows[0]["decision"] == "not_disabled"

    def test_201_07_sedentary_advanced_hs_direct_entry_unskilled_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "high_school_direct_entry", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.07"
        assert rows[0]["decision"] == "not_disabled"

    # Table 1 – Sedentary, closely approaching advanced age (50-54)

    def test_201_09_sedentary_caa_limited_unskilled_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "closely_approaching_advanced", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.09"
        assert rows[0]["decision"] == "disabled"

    def test_201_10_sedentary_caa_limited_nontransferable_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "closely_approaching_advanced", "limited_or_less", "skilled_nontransferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.10"
        assert rows[0]["decision"] == "disabled"

    def test_201_11_sedentary_caa_limited_transferable_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "closely_approaching_advanced", "limited_or_less", "skilled_transferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.11"
        assert rows[0]["decision"] == "not_disabled"

    def test_201_12_sedentary_caa_hs_no_entry_unskilled_is_disabled(self, session):
        rows = self._lookup(session, "sedentary", "closely_approaching_advanced", "high_school_no_direct_entry", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.12"
        assert rows[0]["decision"] == "disabled"

    def test_201_13_sedentary_caa_hs_no_entry_nontransferable_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "closely_approaching_advanced", "high_school_no_direct_entry", "skilled_nontransferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.13"
        assert rows[0]["decision"] == "not_disabled"

    # Table 1 – Sedentary, younger individuals

    def test_201_17_sedentary_younger45_limited_unskilled_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "younger_45_49", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.17"
        assert rows[0]["decision"] == "not_disabled"

    def test_201_25_sedentary_younger1844_limited_unskilled_is_not_disabled(self, session):
        rows = self._lookup(session, "sedentary", "younger_18_44", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "201.25"
        assert rows[0]["decision"] == "not_disabled"

    # Table 2 – Light RFC

    def test_202_01_light_advanced_limited_unskilled_is_disabled(self, session):
        rows = self._lookup(session, "light", "advanced", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "202.01"
        assert rows[0]["decision"] == "disabled"

    def test_202_02_light_advanced_limited_nontransferable_is_disabled(self, session):
        rows = self._lookup(session, "light", "advanced", "limited_or_less", "skilled_nontransferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "202.02"
        assert rows[0]["decision"] == "disabled"

    def test_202_03_light_advanced_limited_transferable_is_not_disabled(self, session):
        rows = self._lookup(session, "light", "advanced", "limited_or_less", "skilled_transferable")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "202.03"
        assert rows[0]["decision"] == "not_disabled"

    def test_202_09_light_caa_limited_unskilled_is_not_disabled(self, session):
        rows = self._lookup(session, "light", "closely_approaching_advanced", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "202.09"
        assert rows[0]["decision"] == "not_disabled"

    # Table 3 – Medium RFC

    def test_203_01_medium_advanced_marginal_none_is_disabled(self, session):
        rows = self._lookup(session, "medium", "advanced", "marginal", "none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "203.01"
        assert rows[0]["decision"] == "disabled"

    def test_203_02_medium_advanced_limited_unskilled_is_not_disabled(self, session):
        rows = self._lookup(session, "medium", "advanced", "limited_or_less", "unskilled_or_none")
        assert len(rows) == 1
        assert rows[0]["rule_number"] == "203.02"
        assert rows[0]["decision"] == "not_disabled"

    # Edge: unknown combination returns no rows (no spurious matches)

    def test_unknown_combination_returns_empty(self, session):
        rows = self._lookup(session, "sedentary", "advanced", "high_school_direct_entry", "skilled_nontransferable")
        assert len(rows) == 0

    # Result integrity: every RESULTS_IN_DECISION edge decision matches outcome

    def test_decision_matches_outcome_for_all_rules(self, session):
        rows = session.run("""
            MATCH (gr:GridRule)-[:RESULTS_IN_DECISION]->(out:EvaluationOutcome)
            WHERE gr.id STARTS WITH 'gr_2'
            RETURN gr.rule_number AS rule_number, gr.decision AS decision, out.result AS outcome
        """).data()
        assert len(rows) > 0
        for row in rows:
            assert row["decision"] == row["outcome"], (
                f"Rule {row['rule_number']}: decision={row['decision']} but outcome={row['outcome']}"
            )


# ---------------------------------------------------------------------------
# AC2 – Step 5 other-work query (sedentary RFC → ≥3 occupations)
# ---------------------------------------------------------------------------

class TestAC2Step5OtherWork:

    def test_sedentary_rfc_returns_at_least_3_occupations(self, session):
        rows = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_sedentary",
            max_svp=4,
        ).data()
        assert len(rows) >= 3, f"Expected ≥3 sedentary occupations, got {len(rows)}"

    def test_sedentary_rfc_returns_only_sedentary_occupations(self, session):
        rows = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_sedentary",
            max_svp=4,
        ).data()
        for row in rows:
            assert row["physical_demands"] == "sedentary", (
                f"{row['title']} has physical_demands={row['physical_demands']}, expected sedentary"
            )

    def test_sedentary_rfc_includes_known_benchmark_occupations(self, session):
        rows = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_sedentary",
            max_svp=4,
        ).data()
        dot_codes = {row["dot_code"] for row in rows}
        benchmark = {"209.587-010", "249.587-018", "379.367-010"}
        assert benchmark.issubset(dot_codes), (
            f"Expected benchmark sedentary occupations {benchmark - dot_codes} to be present"
        )

    def test_light_rfc_returns_sedentary_and_light_occupations(self, session):
        rows = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_light",
            max_svp=4,
        ).data()
        demands = {row["physical_demands"] for row in rows}
        assert demands == {"sedentary", "light"}, (
            f"Light RFC should return sedentary+light occupations, got {demands}"
        )

    def test_medium_rfc_returns_all_three_demand_levels(self, session):
        rows = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_medium",
            max_svp=4,
        ).data()
        demands = {row["physical_demands"] for row in rows}
        assert demands == {"sedentary", "light", "medium"}, (
            f"Medium RFC should return sedentary+light+medium occupations, got {demands}"
        )

    def test_max_svp_filter_excludes_higher_svp(self, session):
        rows_unskilled = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_sedentary",
            max_svp=2,
        ).data()
        rows_all = session.run(
            STEP5_OTHER_WORK,
            work_level_id="wl_sedentary",
            max_svp=4,
        ).data()
        assert len(rows_unskilled) < len(rows_all), (
            "max_svp=2 should return fewer occupations than max_svp=4"
        )
        for row in rows_unskilled:
            assert row["svp"] <= 2

    def test_all_occupations_have_required_properties(self, session):
        rows = session.run("""
            MATCH (occ:DOTOccupation)
            RETURN occ.dot_code AS dot_code, occ.title AS title,
                   occ.svp AS svp, occ.physical_demands AS physical_demands,
                   occ.skill_level AS skill_level
        """).data()
        for row in rows:
            assert row["dot_code"], f"Missing dot_code: {row}"
            assert row["title"],    f"Missing title: {row}"
            assert row["svp"] in (1, 2, 3, 4), f"Invalid svp {row['svp']}: {row}"
            assert row["physical_demands"] in ("sedentary", "light", "medium"), (
                f"Invalid physical_demands {row['physical_demands']}: {row}"
            )
            assert row["skill_level"] in ("unskilled", "semi_skilled"), (
                f"Invalid skill_level {row['skill_level']}: {row}"
            )
