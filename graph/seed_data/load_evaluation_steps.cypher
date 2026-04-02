// ============================================================================
// TASK 1.4: SSA SEQUENTIAL EVALUATION GRAPH SEED
// ============================================================================
// Seeds the 5-step sequential disability evaluation process as a traversable
// graph. EvaluationStep nodes are connected by IF_YES_GO_TO / IF_NO_GO_TO
// edges. Terminal branches resolve to EvaluationOutcome nodes.
//
// Reference: 20 C.F.R. §§ 404.1520, 416.920
// ============================================================================


// ============================================================================
// STEP 1.4.1: CREATE EVALUATION OUTCOME TERMINAL NODES
// ============================================================================

MERGE (disabled:EvaluationOutcome {id: "outcome_disabled"})
SET disabled.name = "Disabled",
    disabled.result = "disabled",
    disabled.description = "Claimant is entitled to SSI/SSDI benefits";

MERGE (not_disabled:EvaluationOutcome {id: "outcome_not_disabled"})
SET not_disabled.name = "Not Disabled",
    not_disabled.result = "not_disabled",
    not_disabled.description = "Claimant is not entitled to SSI/SSDI benefits";


// ============================================================================
// STEP 1.4.1: CREATE THE 5 EVALUATION STEP NODES
// ============================================================================

MERGE (s1:EvaluationStep {id: "step_1_sga"})
SET s1.step_number      = 1,
    s1.name             = "Substantial Gainful Activity",
    s1.question         = "Is the claimant engaging in substantial gainful activity (SGA)?",
    s1.burden_of_proof  = "SSA",
    s1.cfr_cite         = "20 C.F.R. § 404.1520(b)",
    s1.description      = "If the claimant is performing SGA, the claim is denied without further evaluation. SGA threshold is set annually by SSA.";

MERGE (s2:EvaluationStep {id: "step_2_severity"})
SET s2.step_number      = 2,
    s2.name             = "Severe Medically Determinable Impairment",
    s2.question         = "Does the claimant have a severe medically determinable impairment (MDI) that has lasted or is expected to last 12 continuous months or result in death?",
    s2.burden_of_proof  = "claimant",
    s2.cfr_cite         = "20 C.F.R. § 404.1520(c)",
    s2.description      = "A non-severe impairment does not significantly limit basic work activities. De minimis threshold — ALJ must find at least one severe MDI to continue.";

MERGE (s3:EvaluationStep {id: "step_3_listings"})
SET s3.step_number      = 3,
    s3.name             = "Meets or Equals a Medical Listing",
    s3.question         = "Does the claimant's impairment meet or medically equal a listed impairment in the SSA Blue Book (20 C.F.R. Part 404, Subpart P, Appendix 1)?",
    s3.burden_of_proof  = "claimant",
    s3.cfr_cite         = "20 C.F.R. § 404.1520(d)",
    s3.description      = "If the claimant meets or equals a Listing, disability is established without assessing RFC or vocational factors. RFC assessment begins if this step is not satisfied.";

MERGE (s4:EvaluationStep {id: "step_4_prw"})
SET s4.step_number      = 4,
    s4.name             = "Past Relevant Work",
    s4.question         = "Can the claimant perform their past relevant work (PRW) as actually or generally performed, given their residual functional capacity (RFC)?",
    s4.burden_of_proof  = "claimant",
    s4.cfr_cite         = "20 C.F.R. § 404.1520(f)",
    s4.description      = "RFC is assessed before this step. PRW is work done in the last 15 years, lasting long enough to learn the job, performed at SGA level. Claimant bears burden to show inability to perform PRW.";

MERGE (s5:EvaluationStep {id: "step_5_other_work"})
SET s5.step_number      = 5,
    s5.name             = "Other Work in National Economy",
    s5.question         = "Can the claimant perform any other work that exists in significant numbers in the national economy, considering RFC, age, education, and work experience?",
    s5.burden_of_proof  = "SSA",
    s5.cfr_cite         = "20 C.F.R. § 404.1520(g)",
    s5.description      = "Burden shifts to SSA at Step 5. ALJ may rely on Medical-Vocational Guidelines (Grid Rules) or vocational expert testimony. Grid Rules found at 20 C.F.R. Part 404, Subpart P, Appendix 2.";


// ============================================================================
// STEP 1.4.2: WIRE CONDITIONAL BRANCHING EDGES
// ============================================================================
// Convention:
//   IF_YES_GO_TO  — answer to step question is YES  → follow this edge
//   IF_NO_GO_TO   — answer to step question is NO   → follow this edge
//   outcome       — plain-text label for the branch result
//   disposition   — "disabled" | "not_disabled" | null (continues evaluation)
// ============================================================================

// --- Step 1 branches ---

// Step 1 YES → Not Disabled (currently performing SGA; claim denied)
MATCH (s1:EvaluationStep {id: "step_1_sga"})
MATCH (nd:EvaluationOutcome   {id: "outcome_not_disabled"})
MERGE (s1)-[r:IF_YES_GO_TO]->(nd)
SET r.outcome     = "currently_performing_sga",
    r.disposition = "not_disabled",
    r.note        = "Claim denied at Step 1 — claimant is working at SGA level";

// Step 1 NO → Step 2 (not performing SGA; evaluation continues)
MATCH (s1:EvaluationStep {id: "step_1_sga"})
MATCH (s2:EvaluationStep {id: "step_2_severity"})
MERGE (s1)-[r:IF_NO_GO_TO]->(s2)
SET r.outcome = "not_performing_sga",
    r.note    = "Evaluation continues to Step 2";


// --- Step 2 branches ---

// Step 2 YES → Step 3 (severe MDI found; evaluation continues)
MATCH (s2:EvaluationStep {id: "step_2_severity"})
MATCH (s3:EvaluationStep {id: "step_3_listings"})
MERGE (s2)-[r:IF_YES_GO_TO]->(s3)
SET r.outcome = "severe_impairment_established",
    r.note    = "At least one severe MDI confirmed - evaluation continues to Step 3";

// Step 2 NO → Not Disabled (no severe MDI; claim denied)
MATCH (s2:EvaluationStep {id: "step_2_severity"})
MATCH (nd:EvaluationOutcome   {id: "outcome_not_disabled"})
MERGE (s2)-[r:IF_NO_GO_TO]->(nd)
SET r.outcome     = "no_severe_impairment",
    r.disposition = "not_disabled",
    r.note        = "Claim denied at Step 2 — impairment is not severe";


// --- Step 3 branches ---

// Step 3 YES → Disabled (meets/equals Listing; disability established)
MATCH (s3:EvaluationStep   {id: "step_3_listings"})
MATCH (d:EvaluationOutcome {id: "outcome_disabled"})
MERGE (s3)-[r:IF_YES_GO_TO]->(d)
SET r.outcome     = "meets_or_equals_listing",
    r.disposition = "disabled",
    r.note        = "Disability established at Step 3 — Listing met or equaled";

// Step 3 NO → Step 4 (does not meet Listing; RFC assessed, evaluation continues)
MATCH (s3:EvaluationStep {id: "step_3_listings"})
MATCH (s4:EvaluationStep {id: "step_4_prw"})
MERGE (s3)-[r:IF_NO_GO_TO]->(s4)
SET r.outcome = "does_not_meet_listing",
    r.note    = "RFC assessment required - evaluation continues to Step 4";


// --- Step 4 branches ---

// Step 4 YES → Not Disabled (can perform PRW; claim denied)
MATCH (s4:EvaluationStep  {id: "step_4_prw"})
MATCH (nd:EvaluationOutcome {id: "outcome_not_disabled"})
MERGE (s4)-[r:IF_YES_GO_TO]->(nd)
SET r.outcome     = "can_perform_past_relevant_work",
    r.disposition = "not_disabled",
    r.note        = "Claim denied at Step 4 — claimant can perform PRW";

// Step 4 NO → Step 5 (cannot perform PRW; evaluation continues)
MATCH (s4:EvaluationStep {id: "step_4_prw"})
MATCH (s5:EvaluationStep {id: "step_5_other_work"})
MERGE (s4)-[r:IF_NO_GO_TO]->(s5)
SET r.outcome = "cannot_perform_past_relevant_work",
    r.note    = "Burden shifts to SSA - evaluation continues to Step 5";


// --- Step 5 branches ---

// Step 5 YES → Not Disabled (other work exists; claim denied)
MATCH (s5:EvaluationStep  {id: "step_5_other_work"})
MATCH (nd:EvaluationOutcome {id: "outcome_not_disabled"})
MERGE (s5)-[r:IF_YES_GO_TO]->(nd)
SET r.outcome     = "other_work_exists_in_national_economy",
    r.disposition = "not_disabled",
    r.note        = "Claim denied at Step 5 — significant other work exists";

// Step 5 NO → Disabled (no other work; disability established)
MATCH (s5:EvaluationStep   {id: "step_5_other_work"})
MATCH (d:EvaluationOutcome {id: "outcome_disabled"})
MERGE (s5)-[r:IF_NO_GO_TO]->(d)
SET r.outcome     = "no_other_work_in_national_economy",
    r.disposition = "disabled",
    r.note        = "Disability established at Step 5 — no significant other work exists";


// ============================================================================
// VERIFICATION
// ============================================================================

// Acceptance criterion 1: exactly 5 EvaluationStep nodes
MATCH (e:EvaluationStep) RETURN count(e) AS evaluation_step_count;
// Expected: 5

// Acceptance criterion 2: full five-step traversable path (IF_NO favored path)
MATCH path = (s1:EvaluationStep {id: "step_1_sga"})
             -[:IF_NO_GO_TO]->(s2:EvaluationStep)
             -[:IF_YES_GO_TO]->(s3:EvaluationStep)
             -[:IF_NO_GO_TO]->(s4:EvaluationStep)
             -[:IF_NO_GO_TO]->(s5:EvaluationStep)
             -[:IF_NO_GO_TO]->(outcome:EvaluationOutcome)
RETURN
    [n IN nodes(path) | coalesce(n.name, n.result)] AS evaluation_path,
    outcome.result AS final_disposition;
// Expected: path from SGA → Severity → Listings → PRW → Other Work → disabled

// Acceptance criterion 3: all branching edges present
MATCH (e:EvaluationStep)-[r:IF_YES_GO_TO|IF_NO_GO_TO]->(target)
RETURN
    e.step_number  AS step,
    e.name         AS step_name,
    type(r)        AS branch,
    r.outcome      AS outcome,
    r.disposition  AS disposition,
    labels(target) AS target_type,
    coalesce(target.name, target.result) AS target_name
ORDER BY e.step_number, type(r);
