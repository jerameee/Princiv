"""
Cypher query templates for Princiv graph operations.

All queries are parameterised strings for use with the Neo4j Python driver:
    session.run(TEMPLATE, param1=value1, ...)

Property vocabulary (Task 1.6 GridRule nodes):
    rfc_level        "sedentary" | "light" | "medium"
    age_category     "advanced" | "closely_approaching_advanced" |
                     "younger_45_49" | "younger_18_44"
    education        "marginal" | "limited_or_less" |
                     "high_school_no_direct_entry" | "high_school_direct_entry"
    work_experience  "none" | "unskilled_or_none" |
                     "skilled_nontransferable" | "skilled_transferable"
"""

# ---------------------------------------------------------------------------
# Grid Rule lookup (Appendix 2, 20 C.F.R. Pt. 404, Subpt. P, App. 2)
# ---------------------------------------------------------------------------
# Parameters: rfc_level, age_category, education, work_experience
#
# Returns one row per matching rule:
#   rule_number  str   e.g. "201.01"
#   decision     str   "disabled" | "not_disabled"
#   outcome      str   EvaluationOutcome.result (same value as decision)
#   cfr_cite     str   table citation string

GRID_RULE_LOOKUP = """
MATCH (gr:GridRule {
  rfc_level:       $rfc_level,
  age_category:    $age_category,
  education:       $education,
  work_experience: $work_experience
})-[:RESULTS_IN_DECISION]->(out:EvaluationOutcome)
RETURN
  gr.rule_number AS rule_number,
  gr.decision    AS decision,
  out.result     AS outcome,
  gr.cfr_cite    AS cfr_cite
"""

# ---------------------------------------------------------------------------
# Step 5 other-work query — compatible occupations for a given work level
# ---------------------------------------------------------------------------
# Parameters: work_level_id  e.g. "wl_sedentary"
#             max_svp        int  upper bound on SVP (default 4 = all unskilled+semi-skilled)
#
# Returns one row per compatible occupation:
#   dot_code         str   e.g. "209.587-010"
#   title            str
#   svp              int
#   physical_demands str   "sedentary" | "light" | "medium"
#   skill_level      str   "unskilled" | "semi_skilled"

STEP5_OTHER_WORK = """
MATCH (wl:WorkLevel {id: $work_level_id})-[:COMPATIBLE_WITH_JOBS]->(occ:DOTOccupation)
WHERE occ.svp <= $max_svp
RETURN
  occ.dot_code         AS dot_code,
  occ.title            AS title,
  occ.svp              AS svp,
  occ.physical_demands AS physical_demands,
  occ.skill_level      AS skill_level
ORDER BY occ.svp, occ.title
"""

# ---------------------------------------------------------------------------
# Step 5 via RFC component — traverses RFC → WorkLevel → DOTOccupation
# ---------------------------------------------------------------------------
# Parameters: rfc_component_id  e.g. "rfc_sedentary"
#             max_svp           int  (default 4)

STEP5_VIA_RFC = """
MATCH (rfc:RFCComponent {id: $rfc_component_id})
      -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
      -[:COMPATIBLE_WITH_JOBS]->(occ:DOTOccupation)
WHERE occ.svp <= $max_svp
RETURN
  wl.id                AS work_level_id,
  occ.dot_code         AS dot_code,
  occ.title            AS title,
  occ.svp              AS svp,
  occ.physical_demands AS physical_demands,
  occ.skill_level      AS skill_level
ORDER BY occ.svp, occ.title
"""

# ---------------------------------------------------------------------------
# Full medical-vocational chain lookup (Steps 3-5 combined)
# ---------------------------------------------------------------------------
# Given a medical condition id, traverse the full chain to GridRule decisions.
# Parameters: condition_id  e.g. "mc_degenerative_disc_disease"

MEDEVOC_CHAIN = """
MATCH (mc:MedicalCondition {id: $condition_id})
      -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
      -[:MAPS_TO_RFC]->(rfc:RFCComponent)
      -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
      -[:GOVERNS]->(gr:GridRule)
      -[:RESULTS_IN_DECISION]->(out:EvaluationOutcome)
RETURN
  mc.name         AS condition,
  fl.name         AS limitation,
  rfc.id          AS rfc_component,
  wl.id           AS work_level,
  gr.rule_number  AS rule_number,
  gr.decision     AS decision,
  out.result      AS outcome
ORDER BY gr.rule_number
"""

# ---------------------------------------------------------------------------
# Convenience helpers
# ---------------------------------------------------------------------------

RFC_TO_WORK_LEVEL_ID = {
    "sedentary":  "wl_sedentary",
    "light":      "wl_light",
    "medium":     "wl_medium",
    "heavy":      "wl_heavy",
    "very_heavy": "wl_very_heavy",
}

WORK_LEVEL_TO_RFC_ID = {v: k for k, v in RFC_TO_WORK_LEVEL_ID.items()}
