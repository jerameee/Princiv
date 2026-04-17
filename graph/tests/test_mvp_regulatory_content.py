"""
test_mvp_regulatory_content.py
Acceptance criteria tests for Task 1.5: MVP Regulatory Content

Requires Neo4j running with seed data loaded (schema.cypher,
load_evaluation_steps.cypher, and load_mvp_regulatory_content.cypher).
Auto-skips if Neo4j is unreachable or the driver is not installed.

Environment variables:
  NEO4J_URI      — default: bolt://localhost:7687
  NEO4J_USER     — default: neo4j
  NEO4J_PASSWORD — default: password

Acceptance criteria:
  AC1  Full medical-vocational chain is traversable:
       MedicalCondition → FunctionalLimitation → RFCComponent
       → WorkLevel → GridRule → EvaluationOutcome

  AC2  Listing evidence gap Cypher query returns expected EvidenceType
       nodes for seeded conditions.

  AC3  SSR supersedes chain: MATCH path from SSR 96-7p to SSR 16-3p
       via SUPERSEDES returns correct result.
"""

import os
import pytest

try:
    from neo4j import GraphDatabase
    NEO4J_AVAILABLE = True
except ImportError:
    NEO4J_AVAILABLE = False


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
        pytest.skip("Neo4j not reachable — skipping MVP regulatory content tests")


@pytest.fixture(scope="module")
def session(driver):
    with driver.session() as s:
        yield s


def run_count(session, cypher: str) -> int:
    return session.run(cypher).single()["n"]


# ---------------------------------------------------------------------------
# Node count sanity checks
# ---------------------------------------------------------------------------

class TestNodeCounts:
    """Verify all expected node types were created by the seed file."""

    def test_medical_condition_count(self, session):
        n = run_count(session, "MATCH (mc:MedicalCondition) RETURN count(mc) AS n")
        assert n >= 12, f"Expected ≥12 MedicalCondition nodes, got {n}"

    def test_listing_count(self, session):
        n = run_count(session, "MATCH (l:Listing) RETURN count(l) AS n")
        assert n >= 10, f"Expected ≥10 Listing nodes, got {n}"

    def test_ssr_count(self, session):
        n = run_count(session, "MATCH (ssr:SSR) RETURN count(ssr) AS n")
        assert n >= 12, f"Expected ≥12 SSR nodes, got {n}"

    def test_regulation_count(self, session):
        n = run_count(session, "MATCH (r:Regulation) RETURN count(r) AS n")
        assert n >= 8, f"Expected ≥8 Regulation nodes, got {n}"

    def test_evidence_type_count(self, session):
        n = run_count(session, "MATCH (et:EvidenceType) RETURN count(et) AS n")
        assert n >= 12, f"Expected ≥12 EvidenceType nodes, got {n}"

    def test_functional_limitation_count(self, session):
        n = run_count(session, "MATCH (fl:FunctionalLimitation) RETURN count(fl) AS n")
        assert n >= 6, f"Expected ≥6 FunctionalLimitation nodes, got {n}"

    def test_rfc_component_count(self, session):
        n = run_count(session, "MATCH (rfc:RFCComponent) RETURN count(rfc) AS n")
        assert n >= 5, f"Expected ≥5 RFCComponent nodes, got {n}"

    def test_work_level_count(self, session):
        n = run_count(session, "MATCH (wl:WorkLevel) RETURN count(wl) AS n")
        assert n >= 5, f"Expected ≥5 WorkLevel nodes, got {n}"

    def test_grid_rule_count(self, session):
        n = run_count(session, "MATCH (gr:GridRule) RETURN count(gr) AS n")
        assert n >= 4, f"Expected ≥4 GridRule nodes, got {n}"

    def test_required_medical_condition_ids_present(self, session):
        required_ids = [
            "mc_degenerative_disc_disease",
            "mc_lumbar_spinal_stenosis",
            "mc_osteoarthritis_knee",
            "mc_osteoarthritis_hip",
            "mc_fibromyalgia",
            "mc_rotator_cuff_disorder",
            "mc_major_depressive_disorder",
            "mc_ptsd",
            "mc_schizophrenia",
            "mc_bipolar_i_disorder",
            "mc_generalized_anxiety_disorder",
            "mc_panic_disorder",
        ]
        result = session.run(
            "MATCH (mc:MedicalCondition) WHERE mc.id IN $ids RETURN mc.id AS id",
            ids=required_ids,
        )
        found = {row["id"] for row in result.data()}
        missing = set(required_ids) - found
        assert not missing, f"Missing MedicalCondition nodes: {missing}"

    def test_required_listing_sections_present(self, session):
        required_sections = ["1.02", "1.04", "1.15", "1.16", "1.17", "1.18",
                             "12.03", "12.04", "12.06", "12.15"]
        result = session.run(
            "MATCH (l:Listing) WHERE l.section IN $sections RETURN l.section AS section",
            sections=required_sections,
        )
        found = {row["section"] for row in result.data()}
        missing = set(required_sections) - found
        assert not missing, f"Missing Listing sections: {missing}"


# ---------------------------------------------------------------------------
# AC1: Full medical-vocational chain traversal
# ---------------------------------------------------------------------------

_CHAIN_QUERY = """
MATCH path =
    (mc:MedicalCondition)
    -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
    -[:MAPS_TO_RFC]->(rfc:RFCComponent)
    -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
    -[:GOVERNS]->(gr:GridRule)
    -[:RESULTS_IN]->(outcome:EvaluationOutcome)
RETURN
    mc.id       AS condition_id,
    fl.id       AS limitation_id,
    rfc.id      AS rfc_id,
    wl.id       AS work_level_id,
    gr.id       AS grid_rule_id,
    outcome.id  AS outcome_id,
    outcome.result AS decision
LIMIT 20
"""


class TestAC1MedicalVocationalChain:
    """
    AC1: Full chain traversable:
    MedicalCondition → FunctionalLimitation → RFCComponent
    → WorkLevel → GridRule → EvaluationOutcome
    """

    def test_chain_returns_results(self, session):
        """At least one full 6-hop chain must be traversable."""
        rows = session.run(_CHAIN_QUERY).data()
        assert len(rows) > 0, (
            "AC1 FAILED: No full MedicalCondition→FunctionalLimitation→RFCComponent"
            "→WorkLevel→GridRule→EvaluationOutcome chain found"
        )

    def test_chain_includes_musculoskeletal_condition(self, session):
        """Degenerative Disc Disease must participate in at least one full chain."""
        rows = session.run(
            _CHAIN_QUERY.replace(
                "(mc:MedicalCondition)",
                "(mc:MedicalCondition {id: 'mc_degenerative_disc_disease'})",
            )
        ).data()
        assert len(rows) > 0, (
            "AC1 FAILED: mc_degenerative_disc_disease is not connected to a traversable chain"
        )

    def test_chain_includes_mental_health_condition(self, session):
        """At least one mental health MedicalCondition must participate in a full chain."""
        rows = session.run("""
            MATCH path =
                (mc:MedicalCondition {body_system: 'mental_health'})
                -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
                -[:MAPS_TO_RFC]->(rfc:RFCComponent)
                -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
                -[:GOVERNS]->(gr:GridRule)
                -[:RESULTS_IN]->(outcome:EvaluationOutcome)
            RETURN mc.id AS condition_id
            LIMIT 1
        """).data()
        assert len(rows) > 0, (
            "AC1 FAILED: No mental_health MedicalCondition participates in a full chain"
        )

    def test_chain_reaches_disabled_outcome(self, session):
        """At least one chain must resolve to a 'disabled' EvaluationOutcome."""
        rows = session.run("""
            MATCH path =
                (mc:MedicalCondition)
                -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
                -[:MAPS_TO_RFC]->(rfc:RFCComponent)
                -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
                -[:GOVERNS]->(gr:GridRule)
                -[:RESULTS_IN]->(outcome:EvaluationOutcome {result: 'disabled'})
            RETURN mc.id AS condition_id
            LIMIT 1
        """).data()
        assert len(rows) > 0, (
            "AC1 FAILED: No chain resolves to a 'disabled' EvaluationOutcome"
        )

    def test_chain_reaches_not_disabled_outcome(self, session):
        """At least one chain must resolve to a 'not_disabled' EvaluationOutcome."""
        rows = session.run("""
            MATCH path =
                (mc:MedicalCondition)
                -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
                -[:MAPS_TO_RFC]->(rfc:RFCComponent)
                -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
                -[:GOVERNS]->(gr:GridRule)
                -[:RESULTS_IN]->(outcome:EvaluationOutcome {result: 'not_disabled'})
            RETURN mc.id AS condition_id
            LIMIT 1
        """).data()
        assert len(rows) > 0, (
            "AC1 FAILED: No chain resolves to a 'not_disabled' EvaluationOutcome"
        )

    def test_all_six_chain_node_types_populated(self, session):
        """Every node type in the chain must have at least one node."""
        node_types = {
            "MedicalCondition":    "MATCH (n:MedicalCondition) RETURN count(n) AS n",
            "FunctionalLimitation":"MATCH (n:FunctionalLimitation) RETURN count(n) AS n",
            "RFCComponent":        "MATCH (n:RFCComponent) RETURN count(n) AS n",
            "WorkLevel":           "MATCH (n:WorkLevel) RETURN count(n) AS n",
            "GridRule":            "MATCH (n:GridRule) RETURN count(n) AS n",
            "EvaluationOutcome":   "MATCH (n:EvaluationOutcome) RETURN count(n) AS n",
        }
        for label, query in node_types.items():
            count = run_count(session, query)
            assert count > 0, f"AC1 FAILED: No {label} nodes found"

    def test_grid_rules_have_required_vocational_properties(self, session):
        """All GridRule nodes must carry the four vocational factor properties."""
        rows = session.run("""
            MATCH (gr:GridRule)
            WHERE gr.rfc_level IS NULL
               OR gr.age_category IS NULL
               OR gr.education IS NULL
               OR gr.work_experience IS NULL
            RETURN gr.id AS id
        """).data()
        assert len(rows) == 0, (
            f"AC1 FAILED: GridRule nodes missing vocational properties: "
            f"{[r['id'] for r in rows]}"
        )

    def test_grid_rules_have_decision_property(self, session):
        """Every GridRule must carry a 'decision' property."""
        rows = session.run("""
            MATCH (gr:GridRule)
            WHERE gr.decision IS NULL
            RETURN gr.id AS id
        """).data()
        assert len(rows) == 0, (
            f"AC1 FAILED: GridRule nodes missing 'decision' property: "
            f"{[r['id'] for r in rows]}"
        )

    def test_medical_conditions_have_icd10_codes(self, session):
        """Every MedicalCondition must have icd10_code, body_system, and required arrays."""
        rows = session.run("""
            MATCH (mc:MedicalCondition)
            WHERE mc.icd10_code IS NULL
               OR mc.body_system IS NULL
               OR mc.common_symptoms IS NULL
               OR mc.typical_limitations IS NULL
            RETURN mc.id AS id
        """).data()
        assert len(rows) == 0, (
            f"AC1 FAILED: MedicalCondition nodes missing required properties: "
            f"{[r['id'] for r in rows]}"
        )


# ---------------------------------------------------------------------------
# AC2: Listing evidence gap query
# ---------------------------------------------------------------------------

_EVIDENCE_GAP_QUERY = """
MATCH (mc:MedicalCondition)-[:MAY_MEET_LISTING]->(l:Listing)-[:REQUIRES_EVIDENCE]->(et:EvidenceType)
RETURN
    mc.name   AS condition,
    l.section AS listing,
    et.name   AS evidence_type
ORDER BY mc.name, l.section, et.name
"""


class TestAC2ListingEvidenceGap:
    """
    AC2: Listing evidence gap query returns expected EvidenceType nodes
    for seeded MedicalCondition nodes.
    """

    def test_evidence_gap_query_returns_rows(self, session):
        """The evidence gap query must return at least one row."""
        rows = session.run(_EVIDENCE_GAP_QUERY).data()
        assert len(rows) > 0, (
            "AC2 FAILED: Evidence gap query returned no rows — "
            "check MAY_MEET_LISTING and REQUIRES_EVIDENCE edges"
        )

    def test_all_musculoskeletal_conditions_have_evidence_pathways(self, session):
        """All 6 musculoskeletal MedicalConditions must reach at least one EvidenceType."""
        musculo_ids = [
            "mc_degenerative_disc_disease",
            "mc_lumbar_spinal_stenosis",
            "mc_osteoarthritis_knee",
            "mc_osteoarthritis_hip",
            "mc_fibromyalgia",
            "mc_rotator_cuff_disorder",
        ]
        result = session.run("""
            MATCH (mc:MedicalCondition)-[:MAY_MEET_LISTING]->(l:Listing)
                  -[:REQUIRES_EVIDENCE]->(et:EvidenceType)
            WHERE mc.id IN $ids
            RETURN DISTINCT mc.id AS condition_id
        """, ids=musculo_ids)
        found = {row["condition_id"] for row in result.data()}
        missing = set(musculo_ids) - found
        assert not missing, (
            f"AC2 FAILED: Musculoskeletal conditions without evidence pathways: {missing}"
        )

    def test_priority_mental_health_conditions_have_evidence_pathways(self, session):
        """MDD, PTSD, and Schizophrenia must each reach at least one EvidenceType."""
        mental_ids = [
            "mc_major_depressive_disorder",
            "mc_ptsd",
            "mc_schizophrenia",
        ]
        result = session.run("""
            MATCH (mc:MedicalCondition)-[:MAY_MEET_LISTING]->(l:Listing)
                  -[:REQUIRES_EVIDENCE]->(et:EvidenceType)
            WHERE mc.id IN $ids
            RETURN DISTINCT mc.id AS condition_id
        """, ids=mental_ids)
        found = {row["condition_id"] for row in result.data()}
        missing = set(mental_ids) - found
        assert not missing, (
            f"AC2 FAILED: Mental health conditions without evidence pathways: {missing}"
        )

    def test_treating_source_opinion_required_by_multiple_listings(self, session):
        """Treating source opinion must be required evidence for at least 5 Listings."""
        n = run_count(session, """
            MATCH (l:Listing)-[:REQUIRES_EVIDENCE]->
                  (et:EvidenceType {id: 'et_treating_source_opinion'})
            RETURN count(l) AS n
        """)
        assert n >= 5, (
            f"AC2 FAILED: Treating source opinion required by only {n} Listings, expected ≥5"
        )

    def test_imaging_required_for_musculoskeletal_listings(self, session):
        """At least 4 musculoskeletal Listings must require imaging evidence."""
        rows = session.run("""
            MATCH (l:Listing)-[:REQUIRES_EVIDENCE]->(et:EvidenceType)
            WHERE l.body_system = 'musculoskeletal'
              AND et.id IN ['et_imaging_study', 'et_mri_or_ct_imaging']
            RETURN DISTINCT l.section AS section
        """).data()
        assert len(rows) >= 4, (
            f"AC2 FAILED: Only {len(rows)} musculoskeletal Listings require imaging, expected ≥4"
        )

    def test_psychiatric_evaluation_required_for_mental_listings(self, session):
        """All 12.xx Listings must require a psychiatric evaluation."""
        rows = session.run("""
            MATCH (l:Listing)
            WHERE l.body_system = 'mental_health'
              AND NOT (l)-[:REQUIRES_EVIDENCE]->
                      (:EvidenceType {id: 'et_psychiatric_evaluation'})
            RETURN l.section AS section
        """).data()
        assert len(rows) == 0, (
            f"AC2 FAILED: Mental health Listings missing psychiatric_evaluation requirement: "
            f"{[r['section'] for r in rows]}"
        )

    def test_may_meet_listing_edges_have_confidence_property(self, session):
        """Every MAY_MEET_LISTING edge must carry a confidence property."""
        rows = session.run("""
            MATCH (mc:MedicalCondition)-[r:MAY_MEET_LISTING]->(l:Listing)
            WHERE r.confidence IS NULL
            RETURN mc.id AS condition, l.section AS listing
        """).data()
        assert len(rows) == 0, (
            f"AC2 FAILED: MAY_MEET_LISTING edges missing confidence property: {rows}"
        )

    def test_listing_1_16_requires_functional_capacity_evaluation(self, session):
        """Listing 1.16 (lumbar stenosis / cauda equina) must require FCE evidence."""
        rows = session.run("""
            MATCH (l:Listing {section: '1.16'})
                  -[:REQUIRES_EVIDENCE]->
                  (et:EvidenceType {id: 'et_functional_capacity_evaluation'})
            RETURN l.section AS section
        """).data()
        assert len(rows) == 1, (
            "AC2 FAILED: Listing 1.16 does not require functional_capacity_evaluation"
        )

    def test_listing_12_15_requires_trauma_history(self, session):
        """Listing 12.15 (PTSD/trauma) must require trauma history documentation."""
        rows = session.run("""
            MATCH (l:Listing {section: '12.15'})
                  -[:REQUIRES_EVIDENCE]->
                  (et:EvidenceType {id: 'et_trauma_history_documentation'})
            RETURN l.section AS section
        """).data()
        assert len(rows) == 1, (
            "AC2 FAILED: Listing 12.15 does not require trauma_history_documentation"
        )


# ---------------------------------------------------------------------------
# AC3: SSR supersedes chain
# ---------------------------------------------------------------------------

class TestAC3SSRSupersedesChain:
    """
    AC3: SSR supersedes chain — MATCH path from SSR 96-7p to SSR 16-3p
    via SUPERSEDES returns correct path and node properties.
    """

    def test_supersedes_edge_exists(self, session):
        """SSR 16-3p must have exactly one SUPERSEDES edge pointing to SSR 96-7p."""
        rows = session.run("""
            MATCH (new_ssr:SSR)-[:SUPERSEDES]->(old_ssr:SSR)
            WHERE old_ssr.number = '96-7p'
            RETURN new_ssr.number AS superseding, old_ssr.number AS superseded
        """).data()
        assert len(rows) == 1, (
            f"AC3 FAILED: Expected exactly 1 SUPERSEDES edge to SSR 96-7p, found {len(rows)}"
        )
        assert rows[0]["superseding"] == "16-3p", (
            f"AC3 FAILED: Expected SSR 16-3p to supersede 96-7p, "
            f"got {rows[0]['superseding']}"
        )

    def test_superseded_ssr_status_is_superseded(self, session):
        """SSR 96-7p must carry current_status='superseded'."""
        row = session.run(
            "MATCH (ssr:SSR {number: '96-7p'}) RETURN ssr.current_status AS status"
        ).single()
        assert row is not None, "AC3 FAILED: SSR 96-7p node not found"
        assert row["status"] == "superseded", (
            f"AC3 FAILED: SSR 96-7p current_status is '{row['status']}', expected 'superseded'"
        )

    def test_superseding_ssr_is_active(self, session):
        """SSR 16-3p must carry current_status='active'."""
        row = session.run(
            "MATCH (ssr:SSR {number: '16-3p'}) RETURN ssr.current_status AS status"
        ).single()
        assert row is not None, "AC3 FAILED: SSR 16-3p node not found"
        assert row["status"] == "active", (
            f"AC3 FAILED: SSR 16-3p current_status is '{row['status']}', expected 'active'"
        )

    def test_supersedes_path_traversable(self, session):
        """Traversing SUPERSEDES* from SSR 16-3p must reach SSR 96-7p with chain_length=1."""
        row = session.run("""
            MATCH path = (new_ssr:SSR {number: '16-3p'})
                         -[:SUPERSEDES*1..3]->
                         (old_ssr:SSR {number: '96-7p'})
            RETURN
                length(path)   AS chain_length,
                new_ssr.number AS from_ssr,
                old_ssr.number AS to_ssr
        """).single()
        assert row is not None, (
            "AC3 FAILED: No SUPERSEDES path found from SSR 16-3p to SSR 96-7p"
        )
        assert row["chain_length"] == 1, (
            f"AC3 FAILED: Chain length is {row['chain_length']}, expected 1 (direct edge)"
        )

    def test_priority_ssrs_all_present(self, session):
        """All 5 priority SSRs specified in the task must be present."""
        priority_ssrs = ["16-3p", "96-8p", "00-4p", "83-10", "85-15"]
        result = session.run(
            "MATCH (ssr:SSR) WHERE ssr.number IN $numbers RETURN ssr.number AS number",
            numbers=priority_ssrs,
        )
        found = {row["number"] for row in result.data()}
        missing = set(priority_ssrs) - found
        assert not missing, (
            f"AC3 FAILED: Priority SSRs not found in graph: {missing}"
        )

    def test_ssr_96_8p_interprets_rfc_regulation(self, session):
        """SSR 96-8p must have an INTERPRETS edge to 20 C.F.R. § 404.1545 (RFC)."""
        row = session.run("""
            MATCH (ssr:SSR {id: 'ssr_96-8p'})-[:INTERPRETS]->(reg:Regulation {id: 'cfr_404-1545'})
            RETURN ssr.number AS ssr, reg.section AS section
        """).single()
        assert row is not None, (
            "AC3 FAILED: SSR 96-8p does not have INTERPRETS edge to cfr_404-1545"
        )

    def test_ssr_00_4p_interprets_significant_jobs_regulation(self, session):
        """SSR 00-4p must have an INTERPRETS edge to 20 C.F.R. § 404.1566."""
        row = session.run("""
            MATCH (ssr:SSR {id: 'ssr_00-4p'})-[:INTERPRETS]->(reg:Regulation {id: 'cfr_404-1566'})
            RETURN ssr.number AS ssr, reg.section AS section
        """).single()
        assert row is not None, (
            "AC3 FAILED: SSR 00-4p does not have INTERPRETS edge to cfr_404-1566"
        )

    def test_ssrs_are_legal_sources(self, session):
        """Every SSR node must also carry the LegalSource label."""
        rows = session.run("""
            MATCH (ssr:SSR)
            WHERE NOT 'LegalSource' IN labels(ssr)
            RETURN ssr.id AS id
        """).data()
        assert len(rows) == 0, (
            f"AC3 FAILED: SSR nodes missing LegalSource label: "
            f"{[r['id'] for r in rows]}"
        )

    def test_ssrs_have_required_legal_source_properties(self, session):
        """Every SSR must have source_type, jurisdiction, and current_status."""
        rows = session.run("""
            MATCH (ssr:SSR)
            WHERE ssr.source_type IS NULL
               OR ssr.jurisdiction IS NULL
               OR ssr.current_status IS NULL
            RETURN ssr.id AS id
        """).data()
        assert len(rows) == 0, (
            f"AC3 FAILED: SSR nodes missing LegalSource existence constraint properties: "
            f"{[r['id'] for r in rows]}"
        )
