// ============================================================================
// Task 1.6: Medical-Vocational Guidelines (Appendix 2) + DOT Occupations
// 20 C.F.R. Part 404, Subpart P, Appendix 2
//
// Property vocabulary used in this file (normalized, distinct from Task 1.5 stubs):
//   age_category     : "advanced" | "closely_approaching_advanced" |
//                      "younger_45_49" | "younger_18_44"
//   education        : "marginal" | "limited_or_less" |
//                      "high_school_no_direct_entry" | "high_school_direct_entry"
//   work_experience  : "none" | "unskilled_or_none" |
//                      "skilled_nontransferable" | "skilled_transferable"
//   decision         : "disabled" | "not_disabled"
//
// NOTE: Task 1.5 stub GridRule nodes (gr_201_14, gr_201_28, gr_202_06, gr_203_14)
//       are preserved intact — they use a different property vocabulary and power
//       the 1.5 medical-vocational chain test. The comprehensive rules below are
//       intended for precise Appendix 2 lookup queries.
// ============================================================================


// ============================================================================
// SECTION 1.6.1 – GridRule nodes
// ============================================================================
//   Table 1  Sedentary RFC   Rules 201.xx  (16 rules)
//   Table 2  Light RFC       Rules 202.xx  (6 rules)
//   Table 3  Medium RFC      Rules 203.xx  (4 rules)
// ============================================================================


// ─── Table 1 – Sedentary RFC ─────────────────────────────────────────────────
// Age: advanced (55 or over)

MERGE (gr:GridRule {id: 'gr_201_01'})
SET gr += {
  rule_number: '201.01', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_02'})
SET gr += {
  rule_number: '201.02', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'skilled_nontransferable',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_03'})
SET gr += {
  rule_number: '201.03', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'skilled_transferable',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_04'})
SET gr += {
  rule_number: '201.04', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'high_school_no_direct_entry', work_experience: 'unskilled_or_none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_06'})
SET gr += {
  rule_number: '201.06', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'high_school_no_direct_entry', work_experience: 'skilled_transferable',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_07'})
SET gr += {
  rule_number: '201.07', rfc_level: 'sedentary', age_category: 'advanced',
  education: 'high_school_direct_entry', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

// Age: closely_approaching_advanced (50-54)

MERGE (gr:GridRule {id: 'gr_201_09'})
SET gr += {
  rule_number: '201.09', rfc_level: 'sedentary', age_category: 'closely_approaching_advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_10'})
SET gr += {
  rule_number: '201.10', rfc_level: 'sedentary', age_category: 'closely_approaching_advanced',
  education: 'limited_or_less', work_experience: 'skilled_nontransferable',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_11'})
SET gr += {
  rule_number: '201.11', rfc_level: 'sedentary', age_category: 'closely_approaching_advanced',
  education: 'limited_or_less', work_experience: 'skilled_transferable',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_12'})
SET gr += {
  rule_number: '201.12', rfc_level: 'sedentary', age_category: 'closely_approaching_advanced',
  education: 'high_school_no_direct_entry', work_experience: 'unskilled_or_none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_13'})
SET gr += {
  rule_number: '201.13', rfc_level: 'sedentary', age_category: 'closely_approaching_advanced',
  education: 'high_school_no_direct_entry', work_experience: 'skilled_nontransferable',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

// Age: younger_45_49 (45-49)

MERGE (gr:GridRule {id: 'gr_201_17'})
SET gr += {
  rule_number: '201.17', rfc_level: 'sedentary', age_category: 'younger_45_49',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_20'})
SET gr += {
  rule_number: '201.20', rfc_level: 'sedentary', age_category: 'younger_45_49',
  education: 'high_school_no_direct_entry', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

// Age: younger_18_44 (18-44)

MERGE (gr:GridRule {id: 'gr_201_25'})
SET gr += {
  rule_number: '201.25', rfc_level: 'sedentary', age_category: 'younger_18_44',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};

MERGE (gr:GridRule {id: 'gr_201_27'})
SET gr += {
  rule_number: '201.27', rfc_level: 'sedentary', age_category: 'younger_18_44',
  education: 'high_school_no_direct_entry', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 1'
};


// ─── Table 2 – Light RFC ──────────────────────────────────────────────────────
// Age: advanced (55 or over)

MERGE (gr:GridRule {id: 'gr_202_01'})
SET gr += {
  rule_number: '202.01', rfc_level: 'light', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};

MERGE (gr:GridRule {id: 'gr_202_02'})
SET gr += {
  rule_number: '202.02', rfc_level: 'light', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'skilled_nontransferable',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};

MERGE (gr:GridRule {id: 'gr_202_03'})
SET gr += {
  rule_number: '202.03', rfc_level: 'light', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'skilled_transferable',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};

// Age: closely_approaching_advanced (50-54)

MERGE (gr:GridRule {id: 'gr_202_09'})
SET gr += {
  rule_number: '202.09', rfc_level: 'light', age_category: 'closely_approaching_advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};

// Age: younger_45_49

MERGE (gr:GridRule {id: 'gr_202_17'})
SET gr += {
  rule_number: '202.17', rfc_level: 'light', age_category: 'younger_45_49',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};

// Age: younger_18_44

MERGE (gr:GridRule {id: 'gr_202_21'})
SET gr += {
  rule_number: '202.21', rfc_level: 'light', age_category: 'younger_18_44',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 2'
};


// ─── Table 3 – Medium RFC ─────────────────────────────────────────────────────
// Rule 203.01 is the only Disabled finding in Table 3 — it requires the rare
// combination of advanced age + marginal education (6th grade or below) + no
// prior work experience whatsoever.

MERGE (gr:GridRule {id: 'gr_203_01'})
SET gr += {
  rule_number: '203.01', rfc_level: 'medium', age_category: 'advanced',
  education: 'marginal', work_experience: 'none',
  decision: 'disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 3'
};

MERGE (gr:GridRule {id: 'gr_203_02'})
SET gr += {
  rule_number: '203.02', rfc_level: 'medium', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 3'
};

MERGE (gr:GridRule {id: 'gr_203_10'})
SET gr += {
  rule_number: '203.10', rfc_level: 'medium', age_category: 'closely_approaching_advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 3'
};

MERGE (gr:GridRule {id: 'gr_203_19'})
SET gr += {
  rule_number: '203.19', rfc_level: 'medium', age_category: 'younger_45_49',
  education: 'limited_or_less', work_experience: 'unskilled_or_none',
  decision: 'not_disabled',
  cfr_cite: '20 C.F.R. Pt. 404, Subpt. P, App. 2, Table 3'
};


// ─── RESULTS_IN_DECISION edges ────────────────────────────────────────────────
// Connect all Task 1.6 GridRule nodes to the appropriate EvaluationOutcome.
// Also create legacy RESULTS_IN edges so the 1.5 chain traversal query still
// works against any new nodes that replace stubs in the future.

MATCH (gr:GridRule)
WHERE gr.id IN [
  'gr_201_01','gr_201_02','gr_201_04','gr_201_09','gr_201_10','gr_201_12',
  'gr_202_01','gr_202_02','gr_203_01'
]
MATCH (out:EvaluationOutcome {id: 'outcome_disabled'})
MERGE (gr)-[:RESULTS_IN_DECISION]->(out)
MERGE (gr)-[:RESULTS_IN]->(out);

MATCH (gr:GridRule)
WHERE gr.id IN [
  'gr_201_03','gr_201_06','gr_201_07','gr_201_11','gr_201_13',
  'gr_201_17','gr_201_20','gr_201_25','gr_201_27',
  'gr_202_03','gr_202_09','gr_202_17','gr_202_21',
  'gr_203_02','gr_203_10','gr_203_19'
]
MATCH (out:EvaluationOutcome {id: 'outcome_not_disabled'})
MERGE (gr)-[:RESULTS_IN_DECISION]->(out)
MERGE (gr)-[:RESULTS_IN]->(out);


// ─── GOVERNS edges (WorkLevel → GridRule) ────────────────────────────────────

MATCH (wl:WorkLevel {id: 'wl_sedentary'}), (gr:GridRule)
WHERE gr.rfc_level = 'sedentary'
  AND gr.id IN [
    'gr_201_01','gr_201_02','gr_201_03','gr_201_04','gr_201_06','gr_201_07',
    'gr_201_09','gr_201_10','gr_201_11','gr_201_12','gr_201_13',
    'gr_201_17','gr_201_20','gr_201_25','gr_201_27'
  ]
MERGE (wl)-[:GOVERNS]->(gr);

MATCH (wl:WorkLevel {id: 'wl_light'}), (gr:GridRule)
WHERE gr.rfc_level = 'light'
  AND gr.id IN ['gr_202_01','gr_202_02','gr_202_03','gr_202_09','gr_202_17','gr_202_21']
MERGE (wl)-[:GOVERNS]->(gr);

MATCH (wl:WorkLevel {id: 'wl_medium'}), (gr:GridRule)
WHERE gr.rfc_level = 'medium'
  AND gr.id IN ['gr_203_01','gr_203_02','gr_203_10','gr_203_19']
MERGE (wl)-[:GOVERNS]->(gr);


// ============================================================================
// SECTION 1.6.2 – DOT Occupation nodes
// ============================================================================
// 28 occupations across SVP levels 1-4 (unskilled/semi-skilled) and
// sedentary/light/medium physical demands.
//
// Source: Dictionary of Occupational Titles (DOT), 4th ed. rev. 1991.
// These occupations are commonly cited in SSA Step 5 adjudications.
//
// Labels: :DOTOccupation:Occupation (satisfies both the occupation_id_unique
//         constraint on :Occupation and the occupation_dot_code_index on :DOTOccupation)
// ============================================================================


// ─── Sedentary occupations (SVP 1-4) ─────────────────────────────────────────

MERGE (occ:DOTOccupation:Occupation {id: 'dot_209_587_010'})
SET occ += {
  dot_code: '209.587-010', title: 'Addresser', svp: 2,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 43000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_249_587_018'})
SET occ += {
  dot_code: '249.587-018', title: 'Document Preparer, Microfilming', svp: 2,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 52000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_379_367_010'})
SET occ += {
  dot_code: '379.367-010', title: 'Surveillance System Monitor', svp: 2,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 37000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_209_685_014'})
SET occ += {
  dot_code: '209.685-014', title: 'Microfilm Mounter', svp: 1,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 21000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_239_687_014'})
SET occ += {
  dot_code: '239.687-014', title: 'Telephone Quotation Clerk', svp: 2,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 29000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_205_367_014'})
SET occ += {
  dot_code: '205.367-014', title: 'Call-Out Operator', svp: 2,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 18000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_726_685_066'})
SET occ += {
  dot_code: '726.685-066', title: 'Lens Inserter', svp: 1,
  physical_demands: 'sedentary', skill_level: 'unskilled',
  national_jobs_estimate: 15000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_237_362_026'})
SET occ += {
  dot_code: '237.362-026', title: 'Order Clerk, Food and Beverage', svp: 3,
  physical_demands: 'sedentary', skill_level: 'semi_skilled',
  national_jobs_estimate: 61000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_205_362_014'})
SET occ += {
  dot_code: '205.362-014', title: 'Benefits Authorizer', svp: 4,
  physical_demands: 'sedentary', skill_level: 'semi_skilled',
  national_jobs_estimate: 34000
};


// ─── Light occupations (SVP 1-4) ─────────────────────────────────────────────

MERGE (occ:DOTOccupation:Occupation {id: 'dot_222_587_038'})
SET occ += {
  dot_code: '222.587-038', title: 'Routing Clerk', svp: 2,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 87000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_237_367_014'})
SET occ += {
  dot_code: '237.367-014', title: 'Information Clerk, General', svp: 2,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 112000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_915_463_010'})
SET occ += {
  dot_code: '915.463-010', title: 'Parking Lot Attendant', svp: 2,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 95000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_920_687_014'})
SET occ += {
  dot_code: '920.687-014', title: 'Bagger', svp: 1,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 430000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_323_687_014'})
SET occ += {
  dot_code: '323.687-014', title: 'Cleaner, Commercial or Institutional', svp: 1,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 680000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_699_687_014'})
SET occ += {
  dot_code: '699.687-014', title: 'Production Assembler', svp: 2,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 220000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_319_677_014'})
SET occ += {
  dot_code: '319.677-014', title: 'Dining Room Attendant', svp: 2,
  physical_demands: 'light', skill_level: 'unskilled',
  national_jobs_estimate: 290000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_209_567_014'})
SET occ += {
  dot_code: '209.567-014', title: 'Mail Clerk', svp: 3,
  physical_demands: 'light', skill_level: 'semi_skilled',
  national_jobs_estimate: 110000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_295_367_026'})
SET occ += {
  dot_code: '295.367-026', title: 'Sales Attendant, Retail', svp: 3,
  physical_demands: 'light', skill_level: 'semi_skilled',
  national_jobs_estimate: 440000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_239_567_010'})
SET occ += {
  dot_code: '239.567-010', title: 'Ticket Seller', svp: 3,
  physical_demands: 'light', skill_level: 'semi_skilled',
  national_jobs_estimate: 58000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_706_684_022'})
SET occ += {
  dot_code: '706.684-022', title: 'Electromechanical Equipment Assembler', svp: 4,
  physical_demands: 'light', skill_level: 'semi_skilled',
  national_jobs_estimate: 72000
};


// ─── Medium occupations (SVP 1-4) ────────────────────────────────────────────

MERGE (occ:DOTOccupation:Occupation {id: 'dot_361_684_014'})
SET occ += {
  dot_code: '361.684-014', title: 'Laundry Worker', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 230000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_922_687_058'})
SET occ += {
  dot_code: '922.687-058', title: 'Stock Clerk', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 810000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_599_687_014'})
SET occ += {
  dot_code: '599.687-014', title: 'Hand Packager', svp: 1,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 340000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_446_684_014'})
SET occ += {
  dot_code: '446.684-014', title: 'Groundskeeper', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 190000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_311_677_018'})
SET occ += {
  dot_code: '311.677-018', title: 'Fast Food Worker', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 3200000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_699_685_022'})
SET occ += {
  dot_code: '699.685-022', title: 'Machine Feeder', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 175000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_315_674_018'})
SET occ += {
  dot_code: '315.674-018', title: 'Cook Helper', svp: 2,
  physical_demands: 'medium', skill_level: 'unskilled',
  national_jobs_estimate: 260000
};

MERGE (occ:DOTOccupation:Occupation {id: 'dot_692_685_102'})
SET occ += {
  dot_code: '692.685-102', title: 'Semiconductor Wafer Cleaner', svp: 4,
  physical_demands: 'medium', skill_level: 'semi_skilled',
  national_jobs_estimate: 45000
};


// ─── COMPATIBLE_WITH_JOBS edges (WorkLevel → DOTOccupation) ──────────────────
// A claimant limited to sedentary work can only do sedentary occupations.
// Light RFC can do sedentary + light. Medium RFC can do sedentary + light + medium.

MATCH (wl:WorkLevel {id: 'wl_sedentary'}), (occ:DOTOccupation {physical_demands: 'sedentary'})
MERGE (wl)-[:COMPATIBLE_WITH_JOBS]->(occ);

MATCH (wl:WorkLevel {id: 'wl_light'}), (occ:DOTOccupation)
WHERE occ.physical_demands IN ['sedentary', 'light']
MERGE (wl)-[:COMPATIBLE_WITH_JOBS]->(occ);

MATCH (wl:WorkLevel {id: 'wl_medium'}), (occ:DOTOccupation)
WHERE occ.physical_demands IN ['sedentary', 'light', 'medium']
MERGE (wl)-[:COMPATIBLE_WITH_JOBS]->(occ);


// ============================================================================
// VERIFICATION QUERIES (run manually after loading)
// ============================================================================

// Node counts — expected after loading 1.6 on top of prior tasks:
MATCH (gr:GridRule)    RETURN count(gr)  AS grid_rule_count;       // Expected: ≥26 (4 stubs + 26 new)
MATCH (occ:DOTOccupation) RETURN count(occ) AS dot_occ_count;     // Expected: 28

// AC1: Grid rule lookup — sedentary + advanced + limited + unskilled → disabled, rule 201.01
MATCH (gr:GridRule {
  rfc_level: 'sedentary', age_category: 'advanced',
  education: 'limited_or_less', work_experience: 'unskilled_or_none'
})-[:RESULTS_IN_DECISION]->(out:EvaluationOutcome)
RETURN gr.rule_number AS rule_number, gr.decision AS decision, out.result AS outcome;
// Expected: rule_number=201.01, decision=disabled

// AC2: Step 5 other-work — sedentary RFC returns ≥3 compatible occupations
MATCH (wl:WorkLevel {id: 'wl_sedentary'})-[:COMPATIBLE_WITH_JOBS]->(occ:DOTOccupation)
RETURN occ.dot_code, occ.title, occ.svp, occ.physical_demands
ORDER BY occ.svp, occ.title;
// Expected: ≥3 rows (9 sedentary occupations seeded)
