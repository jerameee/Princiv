// ============================================================================
// TASK 1.5: MVP REGULATORY CONTENT SEED
// ============================================================================
// Populates the knowledge graph with minimum viable content for Sprint 2
// retrieval development. Covers MedicalCondition nodes, Listings, SSRs,
// CFR regulations, and the supporting chain nodes required by acceptance
// criteria testing.
//
// Sections:
//   1.5.1  MedicalCondition nodes (12 — 6 musculoskeletal, 6 mental health)
//   1.5.2  Listing nodes (10) + MAY_MEET_LISTING edges
//   1.5.3  SSR nodes (12) + SUPERSEDES chain
//   1.5.4  CFR Regulation nodes (8) + INTERPRETS edges
//   1.5.5  Supporting chain nodes: FunctionalLimitation, RFCComponent,
//          WorkLevel, GridRule
//   1.5.6  Medical-vocational chain wiring (CAUSES_LIMITATION, MAPS_TO_RFC,
//          DETERMINES_WORK_LEVEL, GOVERNS, RESULTS_IN)
//   1.5.7  EvidenceType nodes (12) + REQUIRES_EVIDENCE edges from Listings
//
// All statements use MERGE for idempotency — safe to re-run.
//
// Acceptance criteria verification queries at the bottom of the file.
//
// References:
//   20 C.F.R. Part 404, Subpart P, Appendices 1 & 2
//   SSA Blue Book (Listing of Impairments, effective April 2, 2021 edition)
//   Social Security Rulings (SSRs), ssa.gov
// ============================================================================


// ============================================================================
// SECTION 1.5.1: MEDICAL CONDITION NODES
// ============================================================================
// 12 nodes — 6 musculoskeletal, 6 mental health
// Required properties: id, name, icd10_code, body_system,
//                      common_symptoms[], typical_limitations[]
// ============================================================================


// --- Musculoskeletal Conditions ---

MERGE (ddd:MedicalCondition {id: "mc_degenerative_disc_disease"})
SET ddd.name                = "Degenerative Disc Disease",
    ddd.icd10_code          = "M47.816",
    ddd.body_system         = "musculoskeletal",
    ddd.common_symptoms     = [
        "chronic low back pain",
        "radiating leg pain (sciatica)",
        "muscle spasm",
        "stiffness after rest",
        "reduced lumbar range of motion"
    ],
    ddd.typical_limitations = [
        "limited standing/walking to less than 2 hours in an 8-hour workday",
        "limited sitting tolerance without position change",
        "no repetitive bending or twisting at the waist",
        "lifting limited to 10 lbs or less",
        "need to alternate sitting and standing"
    ];

MERGE (lss:MedicalCondition {id: "mc_lumbar_spinal_stenosis"})
SET lss.name                = "Lumbar Spinal Stenosis",
    lss.icd10_code          = "M48.06",
    lss.body_system         = "musculoskeletal",
    lss.common_symptoms     = [
        "neurogenic claudication",
        "bilateral leg pain and weakness",
        "numbness in lower extremities",
        "pain relieved by sitting or forward flexion",
        "difficulty ambulating more than one block"
    ],
    lss.typical_limitations = [
        "limited ambulation to less than one block without rest",
        "cannot stand more than 10 minutes at a time",
        "limited stair climbing",
        "may require assistive device",
        "no prolonged walking on uneven terrain"
    ];

MERGE (oak:MedicalCondition {id: "mc_osteoarthritis_knee"})
SET oak.name                = "Osteoarthritis of Knee",
    oak.icd10_code          = "M17.11",
    oak.body_system         = "musculoskeletal",
    oak.common_symptoms     = [
        "joint pain with weight bearing",
        "crepitus on range of motion",
        "joint swelling and effusion",
        "morning stiffness",
        "decreased range of motion"
    ],
    oak.typical_limitations = [
        "limited walking on uneven surfaces",
        "cannot kneel or squat",
        "limited stair climbing",
        "no prolonged standing",
        "cannot operate foot pedals or controls"
    ];

MERGE (oah:MedicalCondition {id: "mc_osteoarthritis_hip"})
SET oah.name                = "Osteoarthritis of Hip",
    oah.icd10_code          = "M16.11",
    oah.body_system         = "musculoskeletal",
    oah.common_symptoms     = [
        "groin or buttock pain",
        "pain with internal rotation of hip",
        "antalgic gait",
        "leg length discrepancy",
        "reduced hip flexion and abduction"
    ],
    oah.typical_limitations = [
        "limited walking to less than one mile",
        "cannot climb ladders or scaffolding",
        "no squatting or prolonged bending",
        "limited bending at the waist",
        "may require assistive device for ambulation"
    ];

MERGE (fibro:MedicalCondition {id: "mc_fibromyalgia"})
SET fibro.name              = "Fibromyalgia",
    fibro.icd10_code        = "M79.3",
    fibro.body_system       = "musculoskeletal",
    fibro.common_symptoms   = [
        "widespread musculoskeletal pain (11+ tender points or widespread pain index)",
        "fatigue and unrefreshing sleep",
        "cognitive dysfunction (fibro fog)",
        "headaches",
        "symptom flares with physical or emotional stress"
    ],
    fibro.typical_limitations = [
        "limited to sedentary or light exertional level",
        "cannot sustain full 8-hour workday without rest breaks",
        "frequent absences due to flares (estimated 2+ days per month)",
        "marked limitation in concentration and pace during flares",
        "need for unscheduled rest periods during the workday"
    ];

MERGE (rcd:MedicalCondition {id: "mc_rotator_cuff_disorder"})
SET rcd.name                = "Rotator Cuff Disorder",
    rcd.icd10_code          = "M75.10",
    rcd.body_system         = "musculoskeletal",
    rcd.common_symptoms     = [
        "shoulder pain with overhead activity",
        "weakness in arm and shoulder",
        "limited range of motion (abduction and external rotation)",
        "night pain disrupting sleep",
        "grinding or catching sensation"
    ],
    rcd.typical_limitations = [
        "no overhead reaching with affected arm",
        "limited reaching in all directions",
        "cannot lift more than 5 lbs with affected arm",
        "limited pushing and pulling",
        "limited fine motor tasks with affected upper extremity"
    ];


// --- Mental Health Conditions ---

MERGE (mdd:MedicalCondition {id: "mc_major_depressive_disorder"})
SET mdd.name                = "Major Depressive Disorder, Recurrent, Severe",
    mdd.icd10_code          = "F33.2",
    mdd.body_system         = "mental_health",
    mdd.common_symptoms     = [
        "persistent depressed mood nearly every day",
        "anhedonia (loss of interest in activities)",
        "psychomotor retardation or agitation",
        "hopelessness and worthlessness",
        "suicidal ideation",
        "hypersomnia or insomnia",
        "impaired memory and concentration"
    ],
    mdd.typical_limitations = [
        "marked limitation in concentration, persistence, and pace",
        "limited ability to maintain regular attendance (2+ absences per month)",
        "cannot manage stress of competitive employment",
        "marked limitation in adapting to workplace changes or demands",
        "poor social interaction with supervisors, coworkers, or public"
    ];

MERGE (ptsd:MedicalCondition {id: "mc_ptsd"})
SET ptsd.name               = "Post-Traumatic Stress Disorder",
    ptsd.icd10_code         = "F43.10",
    ptsd.body_system        = "mental_health",
    ptsd.common_symptoms    = [
        "intrusive recollections and flashbacks",
        "hypervigilance and exaggerated startle response",
        "avoidance of trauma-related stimuli",
        "emotional numbing and detachment",
        "sleep disturbance with trauma nightmares",
        "irritability and anger outbursts"
    ],
    ptsd.typical_limitations = [
        "cannot work in close proximity to others due to hypervigilance",
        "limited ability to handle normal work stress without decompensation",
        "marked limitation in adapting to routine changes in work setting",
        "frequent absences or off-task behavior due to intrusive symptoms",
        "difficulty with authority figures and supervision"
    ];

MERGE (schiz:MedicalCondition {id: "mc_schizophrenia"})
SET schiz.name              = "Schizophrenia",
    schiz.icd10_code        = "F20.9",
    schiz.body_system       = "mental_health",
    schiz.common_symptoms   = [
        "positive symptoms: hallucinations, delusions, disorganized speech",
        "negative symptoms: flat affect, avolition, alogia, anhedonia",
        "cognitive disorganization",
        "social withdrawal and isolation",
        "poor insight into illness"
    ],
    schiz.typical_limitations = [
        "marked-to-extreme limitation in all four Paragraph B functional areas",
        "cannot maintain concentration for extended periods",
        "extreme limitation in social interaction in any work setting",
        "cannot follow complex instructions during acute episodes",
        "requires intensive psychiatric support to maintain baseline"
    ];

MERGE (bp1:MedicalCondition {id: "mc_bipolar_i_disorder"})
SET bp1.name                = "Bipolar I Disorder",
    bp1.icd10_code          = "F31.9",
    bp1.body_system         = "mental_health",
    bp1.common_symptoms     = [
        "manic episodes with grandiosity and decreased need for sleep",
        "depressive episodes with anhedonia and psychomotor retardation",
        "rapid cycling in some presentations",
        "impaired judgment during manic phases",
        "possible psychotic features during severe episodes"
    ],
    bp1.typical_limitations = [
        "unpredictable attendance due to mood cycling",
        "limited concentration during depressive phases",
        "poor judgment during manic phases creates workplace safety concerns",
        "marked limitation in adapting to work demands during mood episodes",
        "difficulty sustaining consistent work pace across full workweek"
    ];

MERGE (gad:MedicalCondition {id: "mc_generalized_anxiety_disorder"})
SET gad.name                = "Generalized Anxiety Disorder",
    gad.icd10_code          = "F41.1",
    gad.body_system         = "mental_health",
    gad.common_symptoms     = [
        "excessive uncontrollable worry about multiple domains",
        "restlessness and feeling on edge",
        "fatigue and irritability",
        "difficulty concentrating",
        "muscle tension and sleep disturbance"
    ],
    gad.typical_limitations = [
        "limited ability to work under time pressure or production quotas",
        "cannot handle normal work stress without symptom exacerbation",
        "difficulty concentrating on tasks for extended periods",
        "avoidance of social or performance-based situations",
        "somatic symptoms (headaches, GI complaints) further reduce productivity"
    ];

MERGE (panic:MedicalCondition {id: "mc_panic_disorder"})
SET panic.name              = "Panic Disorder",
    panic.icd10_code        = "F41.0",
    panic.body_system       = "mental_health",
    panic.common_symptoms   = [
        "recurrent unexpected panic attacks with palpitations and shortness of breath",
        "derealization or depersonalization during attacks",
        "fear of losing control or dying",
        "anticipatory anxiety between attacks",
        "agoraphobic avoidance of triggering situations"
    ],
    panic.typical_limitations = [
        "cannot work in crowded or enclosed environments",
        "limited ability to leave home due to agoraphobia",
        "unexpected absences or early departures during panic episodes",
        "cannot work in high-stress or unpredictable settings",
        "avoidance of public transportation limits job access"
    ];


// ============================================================================
// SECTION 1.5.2: LISTING NODES + MAY_MEET_LISTING EDGES
// ============================================================================
// Musculoskeletal: 1.02, 1.04, 1.15, 1.16, 1.17, 1.18 (Body System 1.00)
// Mental health:   12.03, 12.04, 12.06, 12.15 (Body System 12.00)
// Blue Book edition: April 2, 2021 (listings 1.15–1.18 are new in this edition)
// ============================================================================


// --- Musculoskeletal Listings (Body System 1.00) ---

MERGE (l102:Listing {id: "listing_1_02"})
SET l102.section          = "1.02",
    l102.title            = "Major Dysfunction of a Joint(s) Due to Any Cause",
    l102.body_system      = "musculoskeletal",
    l102.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.02",
    l102.edition_date     = "2002-10-25",
    l102.criteria_summary = "Characterized by gross anatomical deformity (subluxation, contracture, bony or fibrous ankylosis, instability) and chronic joint pain and stiffness with signs of limitation of motion or abnormal motion. Requires findings on appropriate medically acceptable imaging of joint space narrowing, bony destruction, or ankylosis. Satisfied by: (A) involvement of one major peripheral weight-bearing joint (hip, knee, ankle) resulting in inability to ambulate effectively; or (B) involvement of one major peripheral joint in each upper extremity (shoulder, elbow, wrist-hand) resulting in inability to perform fine and gross movements effectively.",
    l102.evidence_required = ["imaging_study", "treating_source_opinion", "physical_examination_findings"];

MERGE (l104:Listing {id: "listing_1_04"})
SET l104.section          = "1.04",
    l104.title            = "Disorders of the Spine",
    l104.body_system      = "musculoskeletal",
    l104.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.04",
    l104.edition_date     = "2002-10-25",
    l104.criteria_summary = "Herniation of nucleus pulposus, spinal arachnoiditis, or lumbar spinal stenosis resulting in compromise of a nerve root (including the cauda equina) or the spinal cord. Satisfied by: (A) nerve root compression with neuro-anatomic distribution of pain, limitation of spine motion, motor loss (atrophy with muscle weakness) accompanied by sensory or reflex loss; (B) spinal arachnoiditis confirmed by operative note or pathology report; or (C) lumbar spinal stenosis resulting in pseudoclaudication established by findings on appropriate medically acceptable imaging.",
    l104.evidence_required = ["mri_or_ct_imaging", "nerve_conduction_study", "treating_source_opinion"];

MERGE (l115:Listing {id: "listing_1_15"})
SET l115.section          = "1.15",
    l115.title            = "Disorders of the Skeletal Spine Resulting in Compromise of a Nerve Root",
    l115.body_system      = "musculoskeletal",
    l115.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.15",
    l115.edition_date     = "2021-04-02",
    l115.criteria_summary = "Effective April 2, 2021. Requires all of: (A) Neuro-anatomic (radicular) distribution of pain, paresthesia, or muscle fatigue; (B) Radicular distribution of neurological signs present during examination; (C) Findings on medically acceptable imaging consistent with compromise of a nerve root in the cervical or lumbosacral spine; (D) Impairment-related physical limitation of musculoskeletal functioning lasting or expected to last 12+ continuous months, with at least one of: inability to use upper extremity(ies), or inability to ambulate effectively.",
    l115.evidence_required = ["mri_or_ct_imaging", "physical_examination_findings", "treating_source_opinion"];

MERGE (l116:Listing {id: "listing_1_16"})
SET l116.section          = "1.16",
    l116.title            = "Lumbar Spinal Stenosis Resulting in Compromise of the Cauda Equina",
    l116.body_system      = "musculoskeletal",
    l116.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.16",
    l116.edition_date     = "2021-04-02",
    l116.criteria_summary = "Effective April 2, 2021. Requires all of: (A) Symptoms of neurogenic claudication (pain, burning, or weakness in one or both lower extremities); (B) Signs of radicular distribution of neurological signs, or skin changes associated with neurogenic claudication; (C) Findings on medically acceptable imaging consistent with lumbar spinal stenosis; (D) Impairment-related physical limitation of musculoskeletal functioning lasting 12+ months, with at least one of: inability to ambulate effectively, or inability to use upper extremity(ies).",
    l116.evidence_required = ["mri_or_ct_imaging", "physical_examination_findings", "treating_source_opinion", "functional_capacity_evaluation"];

MERGE (l117:Listing {id: "listing_1_17"})
SET l117.section          = "1.17",
    l117.title            = "Reconstructive Surgery or Surgical Arthrodesis of a Major Weight-Bearing Joint",
    l117.body_system      = "musculoskeletal",
    l117.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.17",
    l117.edition_date     = "2021-04-02",
    l117.criteria_summary = "Effective April 2, 2021. Requires all of: (A) History of reconstructive surgery or surgical arthrodesis of a major weight-bearing joint; (B) Impairment-related physical limitation of musculoskeletal functioning lasting or expected to last 12+ months; (C) A documented medical need for a walker, bilateral canes, bilateral crutches, or a wheeled and seated mobility device.",
    l117.evidence_required = ["operative_report", "imaging_study", "treating_source_opinion"];

MERGE (l118:Listing {id: "listing_1_18"})
SET l118.section          = "1.18",
    l118.title            = "Abnormality of a Major Joint(s) in Any Extremity",
    l118.body_system      = "musculoskeletal",
    l118.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 1.18",
    l118.edition_date     = "2021-04-02",
    l118.criteria_summary = "Effective April 2, 2021. Requires all of: (A) Chronic joint pain or stiffness; (B) Abnormal motion, instability, or immobility of the affected joint(s); (C) Anatomical abnormality of the affected joint(s) noted on appropriate medically acceptable imaging; (D) Impairment-related physical limitation of musculoskeletal functioning lasting 12+ months, with at least one of: inability to ambulate effectively, or inability to use upper extremity(ies).",
    l118.evidence_required = ["imaging_study", "physical_examination_findings", "treating_source_opinion"];


// --- Mental Health Listings (Body System 12.00) ---

MERGE (l1203:Listing {id: "listing_12_03"})
SET l1203.section          = "12.03",
    l1203.title            = "Schizophrenia Spectrum and Other Psychotic Disorders",
    l1203.body_system      = "mental_health",
    l1203.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 12.03",
    l1203.edition_date     = "2017-01-17",
    l1203.criteria_summary = "Satisfied by A+B or A+C. Paragraph A: Medical documentation of one or more of — delusions or hallucinations, disorganized thinking (speech), grossly disorganized or catatonic behavior, or negative symptoms. Paragraph B: Extreme limitation of one, or marked limitation of two, of the four Paragraph B areas (understanding/applying info; interacting with others; concentrating/persisting/pace; adapting/managing self). Paragraph C: Serious and persistent disorder with documented history of 2+ years and evidence of both medical treatment/structured support and marginal adjustment.",
    l1203.evidence_required = ["psychiatric_evaluation", "treating_source_opinion", "mental_status_examination", "inpatient_records"];

MERGE (l1204:Listing {id: "listing_12_04"})
SET l1204.section          = "12.04",
    l1204.title            = "Depressive, Bipolar and Related Disorders",
    l1204.body_system      = "mental_health",
    l1204.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 12.04",
    l1204.edition_date     = "2017-01-17",
    l1204.criteria_summary = "Satisfied by A+B, A+C, or B+C. Paragraph A: Medical documentation of depressive disorder (5+ diagnostic features) or bipolar disorder (with manic or depressive episodes). Paragraph B: Extreme limitation of one, or marked limitation of two, of the four Paragraph B areas. Paragraph C: Serious and persistent disorder with documented history of 2+ years and evidence of both ongoing medical treatment and marginal adjustment.",
    l1204.evidence_required = ["psychiatric_evaluation", "treating_source_opinion", "mental_status_examination", "psychological_testing"];

MERGE (l1206:Listing {id: "listing_12_06"})
SET l1206.section          = "12.06",
    l1206.title            = "Anxiety and Obsessive-Compulsive Disorders",
    l1206.body_system      = "mental_health",
    l1206.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 12.06",
    l1206.edition_date     = "2017-01-17",
    l1206.criteria_summary = "Satisfied by A+B or A+C. Paragraph A: Medical documentation of anxiety disorder, panic disorder with or without agoraphobia, social anxiety disorder, OCD, or other anxiety or obsessive-compulsive disorder. Paragraph B: Extreme limitation of one, or marked limitation of two, of the four Paragraph B areas. Paragraph C: Serious and persistent disorder with documented history of 2+ years.",
    l1206.evidence_required = ["psychiatric_evaluation", "treating_source_opinion", "mental_status_examination"];

MERGE (l1215:Listing {id: "listing_12_15"})
SET l1215.section          = "12.15",
    l1215.title            = "Trauma- and Stressor-Related Disorders",
    l1215.body_system      = "mental_health",
    l1215.cfr_cite         = "20 C.F.R. Part 404, Subpart P, Appendix 1, § 12.15",
    l1215.edition_date     = "2017-01-17",
    l1215.criteria_summary = "Satisfied by A+B or A+C. Paragraph A: Medical documentation of all of — exposure to actual or threatened death, violence, or serious injury; subsequent involuntary re-experiencing of the traumatic event; avoidance of external reminders; disturbance in mood and behavior; and increases in arousal and reactivity. Paragraph B: Extreme limitation of one, or marked limitation of two, of the four Paragraph B areas. Paragraph C: Serious and persistent disorder with documented 2-year history.",
    l1215.evidence_required = ["psychiatric_evaluation", "treating_source_opinion", "mental_status_examination", "trauma_history_documentation"];


// --- MAY_MEET_LISTING edges (MedicalCondition → Listing) ---

// Degenerative Disc Disease
MATCH (mc:MedicalCondition {id: "mc_degenerative_disc_disease"})
MATCH (l:Listing {id: "listing_1_15"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.70,
    rationale: "Disc herniation causing nerve root compression is the paradigmatic mechanism addressed by Listing 1.15"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_degenerative_disc_disease"})
MATCH (l:Listing {id: "listing_1_04"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.60,
    rationale: "Herniation of nucleus pulposus with nerve root compromise satisfies Listing 1.04(A)"
}]->(l);

// Lumbar Spinal Stenosis
MATCH (mc:MedicalCondition {id: "mc_lumbar_spinal_stenosis"})
MATCH (l:Listing {id: "listing_1_16"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.80,
    rationale: "Lumbar stenosis with cauda equina compromise producing neurogenic claudication is the paradigmatic Listing 1.16 case"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_lumbar_spinal_stenosis"})
MATCH (l:Listing {id: "listing_1_04"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.65,
    rationale: "Stenosis producing pseudoclaudication may satisfy Listing 1.04(C)"
}]->(l);

// Osteoarthritis of Knee
MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_knee"})
MATCH (l:Listing {id: "listing_1_02"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.60,
    rationale: "Knee is a major peripheral weight-bearing joint; severe OA causing inability to ambulate effectively satisfies Listing 1.02(A)"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_knee"})
MATCH (l:Listing {id: "listing_1_18"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.65,
    rationale: "Anatomical joint abnormality with chronic pain and functionally significant motion limitation satisfies Listing 1.18"
}]->(l);

// Osteoarthritis of Hip
MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_hip"})
MATCH (l:Listing {id: "listing_1_02"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.65,
    rationale: "Hip is a major peripheral weight-bearing joint; inability to ambulate effectively satisfies Listing 1.02(A)"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_hip"})
MATCH (l:Listing {id: "listing_1_17"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.50,
    rationale: "Post-hip arthroplasty claimants requiring assistive device may satisfy Listing 1.17"
}]->(l);

// Fibromyalgia
MATCH (mc:MedicalCondition {id: "mc_fibromyalgia"})
MATCH (l:Listing {id: "listing_1_18"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.35,
    rationale: "Fibromyalgia rarely meets a Listing directly; Listing 1.18 is the closest musculoskeletal analog when joint involvement is documented (per SSR 12-2p)"
}]->(l);

// Rotator Cuff Disorder
MATCH (mc:MedicalCondition {id: "mc_rotator_cuff_disorder"})
MATCH (l:Listing {id: "listing_1_02"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.50,
    rationale: "Shoulder is a major peripheral joint; inability to perform fine and gross movements effectively satisfies Listing 1.02(B)"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_rotator_cuff_disorder"})
MATCH (l:Listing {id: "listing_1_18"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.55,
    rationale: "Documented rotator cuff tear with chronic pain and measurable motion limitation satisfies Listing 1.18"
}]->(l);

// Major Depressive Disorder
MATCH (mc:MedicalCondition {id: "mc_major_depressive_disorder"})
MATCH (l:Listing {id: "listing_12_04"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.75,
    rationale: "MDD with recurrent severe episodes is a prototypical Listing 12.04 depressive disorder"
}]->(l);

// Bipolar I Disorder
MATCH (mc:MedicalCondition {id: "mc_bipolar_i_disorder"})
MATCH (l:Listing {id: "listing_12_04"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.70,
    rationale: "Bipolar I Disorder is explicitly named in Listing 12.04 (depressive, bipolar and related disorders)"
}]->(l);

// PTSD
MATCH (mc:MedicalCondition {id: "mc_ptsd"})
MATCH (l:Listing {id: "listing_12_15"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.80,
    rationale: "PTSD is the paradigmatic Listing 12.15 trauma- and stressor-related disorder"
}]->(l);

MATCH (mc:MedicalCondition {id: "mc_ptsd"})
MATCH (l:Listing {id: "listing_12_06"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.40,
    rationale: "PTSD anxiety component may also satisfy Listing 12.06 anxiety disorder criteria in some adjudications"
}]->(l);

// Generalized Anxiety Disorder
MATCH (mc:MedicalCondition {id: "mc_generalized_anxiety_disorder"})
MATCH (l:Listing {id: "listing_12_06"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.70,
    rationale: "GAD is a core anxiety disorder explicitly covered under Listing 12.06"
}]->(l);

// Panic Disorder
MATCH (mc:MedicalCondition {id: "mc_panic_disorder"})
MATCH (l:Listing {id: "listing_12_06"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.65,
    rationale: "Panic disorder with agoraphobia is explicitly covered under Listing 12.06"
}]->(l);

// Schizophrenia
MATCH (mc:MedicalCondition {id: "mc_schizophrenia"})
MATCH (l:Listing {id: "listing_12_03"})
MERGE (mc)-[:MAY_MEET_LISTING {
    confidence: 0.85,
    rationale: "Schizophrenia is the paradigmatic Listing 12.03 schizophrenia spectrum disorder"
}]->(l);


// ============================================================================
// SECTION 1.5.3: SSR NODES + SUPERSEDES CHAIN
// ============================================================================
// 12 SSR nodes as :SSR:LegalSource
// Existence constraints on LegalSource require: source_type, jurisdiction,
// current_status
// SUPERSEDES edge: (SSR 16-3p)-[:SUPERSEDES]->(SSR 96-7p)
// ============================================================================

MERGE (ssr_16_3p:SSR:LegalSource {id: "ssr_16-3p"})
SET ssr_16_3p.number         = "16-3p",
    ssr_16_3p.title          = "Titles II and XVI: Evaluation of Symptoms in Disability Claims",
    ssr_16_3p.effective_date = date("2016-03-28"),
    ssr_16_3p.policy_topic   = "evaluation_of_symptoms",
    ssr_16_3p.current_status = "active",
    ssr_16_3p.source_type    = "ssr",
    ssr_16_3p.jurisdiction   = "US",
    ssr_16_3p.summary        = "Eliminates use of the term 'credibility' and clarifies that adjudicators must evaluate claimant's statements about the intensity, persistence, and limiting effects of symptoms using a two-step process and all relevant evidence. Step 1: determine whether a medically determinable impairment could reasonably be expected to produce the alleged symptoms. Step 2: evaluate the intensity and persistence of symptoms. Requires consideration of: activities of daily living, location/duration/frequency/intensity of pain, precipitating and aggravating factors, medications and side effects, treatment and other measures, and other factors.";

MERGE (ssr_96_7p:SSR:LegalSource {id: "ssr_96-7p"})
SET ssr_96_7p.number         = "96-7p",
    ssr_96_7p.title          = "Titles II and XVI: Evaluation of Symptoms in Disability Claims: Assessing the Credibility of an Individual's Statements",
    ssr_96_7p.effective_date = date("1996-07-02"),
    ssr_96_7p.policy_topic   = "evaluation_of_symptoms",
    ssr_96_7p.current_status = "superseded",
    ssr_96_7p.source_type    = "ssr",
    ssr_96_7p.jurisdiction   = "US",
    ssr_96_7p.summary        = "Former policy on evaluating claimant credibility regarding symptom statements. Required ALJ to make explicit credibility finding supported by specific reasons articulated in the decision. Superseded by SSR 16-3p effective March 28, 2016, which eliminated the term 'credibility' and replaced the framework with a symptom evaluation process focused on intensity, persistence, and limiting effects.";

MERGE (ssr_96_8p:SSR:LegalSource {id: "ssr_96-8p"})
SET ssr_96_8p.number         = "96-8p",
    ssr_96_8p.title          = "Titles II and XVI: Assessing Residual Functional Capacity in Initial Claims",
    ssr_96_8p.effective_date = date("1996-07-02"),
    ssr_96_8p.policy_topic   = "residual_functional_capacity",
    ssr_96_8p.current_status = "active",
    ssr_96_8p.source_type    = "ssr",
    ssr_96_8p.jurisdiction   = "US",
    ssr_96_8p.summary        = "Defines RFC as an assessment of maximum remaining ability to do sustained work-related physical and mental activities in a work setting on a regular and continuing basis — 8 hours a day, 5 days a week, or equivalent schedule. RFC is not the least claimant can do but the most. Requires function-by-function narrative discussion describing how evidence supports each conclusion. Must address physical exertional, nonexertional, and mental limitations separately.";

MERGE (ssr_00_4p:SSR:LegalSource {id: "ssr_00-4p"})
SET ssr_00_4p.number         = "00-4p",
    ssr_00_4p.title          = "Titles II and XVI: Use of Vocational Expert and Vocational Specialist Evidence, and Other Reliable Occupational Information in Disability Decisions",
    ssr_00_4p.effective_date = date("2000-12-04"),
    ssr_00_4p.policy_topic   = "vocational_expert_testimony",
    ssr_00_4p.current_status = "active",
    ssr_00_4p.source_type    = "ssr",
    ssr_00_4p.jurisdiction   = "US",
    ssr_00_4p.summary        = "Requires ALJs to ask vocational experts whether their testimony is consistent with the Dictionary of Occupational Titles (DOT) and Selected Characteristics of Occupations (SCO). ALJ must identify and resolve any apparent conflict between VE testimony and the DOT before relying on VE evidence. Failure to ask the standard DOT-consistency question is a procedural error. VE may provide explanation for deviation from DOT that the ALJ must accept or reject with explanation.";

MERGE (ssr_83_10:SSR:LegalSource {id: "ssr_83-10"})
SET ssr_83_10.number         = "83-10",
    ssr_83_10.title          = "Titles II and XVI: Determining Capability to Do Other Work — the Medical-Vocational Rules of Appendix 2",
    ssr_83_10.effective_date = date("1983-01-01"),
    ssr_83_10.policy_topic   = "exertional_levels_grid_rules",
    ssr_83_10.current_status = "active",
    ssr_83_10.source_type    = "ssr",
    ssr_83_10.jurisdiction   = "US",
    ssr_83_10.summary        = "Defines the five exertional levels: sedentary (lifting up to 10 lbs occasionally, primarily sitting), light (up to 20 lbs occasionally, 10 lbs frequently, standing/walking up to 6 hours), medium (up to 50 lbs occasionally, 25 lbs frequently), heavy (up to 100 lbs occasionally, 50 lbs frequently), very heavy (over 100 lbs occasionally). Explains how Grid Rules at 20 C.F.R. Part 404, Subpart P, Appendix 2 direct conclusions when all four vocational factors (RFC level, age, education, work experience) precisely match a rule.";

MERGE (ssr_85_15:SSR:LegalSource {id: "ssr_85-15"})
SET ssr_85_15.number         = "85-15",
    ssr_85_15.title          = "Titles II and XVI: Capability to Do Other Work — the Medical-Vocational Rules as a Framework for Evaluating Solely Nonexertional Impairments",
    ssr_85_15.effective_date = date("1985-01-01"),
    ssr_85_15.policy_topic   = "nonexertional_impairments",
    ssr_85_15.current_status = "active",
    ssr_85_15.source_type    = "ssr",
    ssr_85_15.jurisdiction   = "US",
    ssr_85_15.summary        = "Provides framework for evaluating solely nonexertional impairments (mental, sensory, skin, postural, manipulative, environmental limitations). Grid Rules do not directly apply when limitations are solely nonexertional; VE testimony or other evidence is required to determine whether significant jobs remain. Provides specific guidance: a claimant who cannot interact with the public can still perform many unskilled jobs; a claimant who cannot handle any degree of stress may be precluded from all work.";

MERGE (ssr_96_2p:SSR:LegalSource {id: "ssr_96-2p"})
SET ssr_96_2p.number         = "96-2p",
    ssr_96_2p.title          = "Titles II and XVI: Giving Controlling Weight to Treating Source Medical Opinions",
    ssr_96_2p.effective_date = date("1996-07-02"),
    ssr_96_2p.policy_topic   = "treating_source_opinions",
    ssr_96_2p.current_status = "active",
    ssr_96_2p.source_type    = "ssr",
    ssr_96_2p.jurisdiction   = "US",
    ssr_96_2p.summary        = "Clarifies when treating source medical opinions receive controlling weight under the treating physician rule (applicable to claims filed before March 27, 2017). Opinion receives controlling weight if: (1) well-supported by medically acceptable clinical and laboratory diagnostic techniques, and (2) not inconsistent with other substantial evidence in the case record. If not given controlling weight, SSA must still consider the opinion and explain the weight assigned with specific reasons.";

MERGE (ssr_96_9p:SSR:LegalSource {id: "ssr_96-9p"})
SET ssr_96_9p.number         = "96-9p",
    ssr_96_9p.title          = "Titles II and XVI: Determining Capability to Do Other Work — Implications of a Residual Functional Capacity for Less Than a Full Range of Sedentary Work",
    ssr_96_9p.effective_date = date("1996-07-02"),
    ssr_96_9p.policy_topic   = "sedentary_rfc_limitations",
    ssr_96_9p.current_status = "active",
    ssr_96_9p.source_type    = "ssr",
    ssr_96_9p.jurisdiction   = "US",
    ssr_96_9p.summary        = "Addresses situations where the claimant cannot perform the full range of sedentary work due to additional nonexertional limitations. Grid Rules cannot be used mechanically when nonexertional limitations further erode the sedentary occupational base. When the occupational base for sedentary work is significantly eroded, VE testimony is required to determine whether significant jobs remain. Addresses sit/stand option, manipulative limitations, and environmental restrictions common to sedentary claimants.";

MERGE (ssr_02_1p:SSR:LegalSource {id: "ssr_02-1p"})
SET ssr_02_1p.number         = "02-1p",
    ssr_02_1p.title          = "Titles II and XVI: Evaluation of Obesity",
    ssr_02_1p.effective_date = date("2002-09-12"),
    ssr_02_1p.policy_topic   = "obesity",
    ssr_02_1p.current_status = "active",
    ssr_02_1p.source_type    = "ssr",
    ssr_02_1p.jurisdiction   = "US",
    ssr_02_1p.summary        = "Following removal of obesity Listing 9.09, SSR 02-1p provides guidance on evaluating obesity as a potentially severe impairment. Obesity must be considered at each step of the sequential evaluation for its effects on other body systems. Obesity may cause or contribute to impairments of the musculoskeletal, cardiovascular, and respiratory body systems. RFC must reflect the combined impact of obesity with any comorbid conditions.";

MERGE (ssr_12_2p:SSR:LegalSource {id: "ssr_12-2p"})
SET ssr_12_2p.number         = "12-2p",
    ssr_12_2p.title          = "Titles II and XVI: Evaluation of Fibromyalgia",
    ssr_12_2p.effective_date = date("2012-07-25"),
    ssr_12_2p.policy_topic   = "fibromyalgia",
    ssr_12_2p.current_status = "active",
    ssr_12_2p.source_type    = "ssr",
    ssr_12_2p.jurisdiction   = "US",
    ssr_12_2p.summary        = "Provides framework for establishing fibromyalgia as a medically determinable impairment (MDI) using American College of Rheumatology 1990 criteria (11+ tender points on examination) or 2010 Preliminary Diagnostic Criteria (widespread pain index and symptom severity scale). Fibromyalgia does not have its own Listing but must be fully evaluated at each step. RFC assessment must account for fluctuating symptoms of pain, fatigue, and cognitive dysfunction that may not appear consistently in medical records.";

MERGE (ssr_18_3p:SSR:LegalSource {id: "ssr_18-3p"})
SET ssr_18_3p.number         = "18-3p",
    ssr_18_3p.title          = "Titles II and XVI: Initial Determinations for Supplemental Security Income — Evaluation of Symptoms",
    ssr_18_3p.effective_date = date("2018-10-25"),
    ssr_18_3p.policy_topic   = "evaluation_of_symptoms_ssi",
    ssr_18_3p.current_status = "active",
    ssr_18_3p.source_type    = "ssr",
    ssr_18_3p.jurisdiction   = "US",
    ssr_18_3p.summary        = "SSI-specific companion ruling to SSR 16-3p applying the same symptom evaluation framework to initial SSI determinations. Emphasizes consistency of alleged symptoms with medical evidence and longitudinal treatment records. Applies the same two-step process: (1) whether MDI could reasonably produce symptoms; (2) evaluate intensity, persistence, and limiting effects of symptoms.";

MERGE (ssr_82_41:SSR:LegalSource {id: "ssr_82-41"})
SET ssr_82_41.number         = "82-41",
    ssr_82_41.title          = "Titles II and XVI: Work Experience as a Vocational Factor",
    ssr_82_41.effective_date = date("1982-01-01"),
    ssr_82_41.policy_topic   = "work_experience_vocational",
    ssr_82_41.current_status = "active",
    ssr_82_41.source_type    = "ssr",
    ssr_82_41.jurisdiction   = "US",
    ssr_82_41.summary        = "Defines how work experience is evaluated as a vocational factor at Step 5. Past relevant work (PRW) is work performed in the last 15 years at SGA level for long enough to learn the job. Addresses transferability of skills: skills are transferable when the skilled or semi-skilled work activities done in past work can be used to meet the requirements of skilled or semi-skilled work activities of other jobs with minimal vocational adjustment. Unskilled work has no transferable skills.";


// --- SSR SUPERSEDES chain ---

MATCH (new_ssr:SSR {id: "ssr_16-3p"})
MATCH (old_ssr:SSR {id: "ssr_96-7p"})
MERGE (new_ssr)-[:SUPERSEDES {
    effective_date: date("2016-03-28"),
    reason:         "SSA eliminated use of the term 'credibility' and clarified that symptom evaluation must focus on intensity, persistence, and limiting effects rather than claimant truthfulness"
}]->(old_ssr);


// ============================================================================
// SECTION 1.5.4: CFR REGULATION NODES + INTERPRETS EDGES
// ============================================================================
// 8 Regulation nodes as :Regulation:LegalSource
// Existence constraints: source_type, jurisdiction, current_status
// INTERPRETS edges from relevant SSR nodes to CFR sections they operationalize
// ============================================================================

MERGE (cfr_1520:Regulation:LegalSource {id: "cfr_404-1520"})
SET cfr_1520.section        = "404.1520",
    cfr_1520.title          = "Evaluation of Disability in General",
    cfr_1520.code           = "20 C.F.R.",
    cfr_1520.cfr_cite       = "20 C.F.R. § 404.1520",
    cfr_1520.jurisdiction   = "US",
    cfr_1520.source_type    = "regulation",
    cfr_1520.current_status = "active",
    cfr_1520.summary        = "Codifies the 5-step sequential evaluation process for disability determinations under Title II (SSDI). Parallel provision at § 416.920 for Title XVI (SSI). Steps: (a) SGA; (b) severe impairment; (c) meets/equals Listing; (d) past relevant work given RFC; (e) other work in national economy given RFC, age, education, and work experience.";

MERGE (cfr_1545:Regulation:LegalSource {id: "cfr_404-1545"})
SET cfr_1545.section        = "404.1545",
    cfr_1545.title          = "Your Residual Functional Capacity",
    cfr_1545.code           = "20 C.F.R.",
    cfr_1545.cfr_cite       = "20 C.F.R. § 404.1545",
    cfr_1545.jurisdiction   = "US",
    cfr_1545.source_type    = "regulation",
    cfr_1545.current_status = "active",
    cfr_1545.summary        = "Defines RFC as the most a claimant can still do despite limitations from all medically determinable impairments, including any related symptoms such as pain. RFC is the maximum sustained work-related activity on a regular and continuing basis. Requires separate assessment of physical, mental, sensory, and other limitations. RFC is used at Steps 4 and 5. Physical RFC expressed in exertional terms (sedentary, light, medium, heavy, very heavy); mental RFC expressed as function-by-function limitations.";

MERGE (cfr_1560:Regulation:LegalSource {id: "cfr_404-1560"})
SET cfr_1560.section        = "404.1560",
    cfr_1560.title          = "When We Will Consider Your Vocational Factors",
    cfr_1560.code           = "20 C.F.R.",
    cfr_1560.cfr_cite       = "20 C.F.R. § 404.1560",
    cfr_1560.jurisdiction   = "US",
    cfr_1560.source_type    = "regulation",
    cfr_1560.current_status = "active",
    cfr_1560.summary        = "Establishes when vocational factors (age, education, work experience) are considered alongside RFC in determining disability. Provides the framework for Steps 4 and 5 vocational analysis. If RFC prevents past relevant work (Step 4), SSA considers RFC combined with vocational factors to determine whether other work exists (Step 5). Grid Rules at Appendix 2 apply when all factors coincide with a rule.";

MERGE (cfr_1561:Regulation:LegalSource {id: "cfr_404-1561"})
SET cfr_1561.section        = "404.1561",
    cfr_1561.title          = "Work Experience as a Vocational Factor",
    cfr_1561.code           = "20 C.F.R.",
    cfr_1561.cfr_cite       = "20 C.F.R. § 404.1561",
    cfr_1561.jurisdiction   = "US",
    cfr_1561.source_type    = "regulation",
    cfr_1561.current_status = "active",
    cfr_1561.summary        = "Defines how past work experience is considered. Considers the type, complexity, and skill requirements of prior work. Distinguishes among unskilled (SVP 1-2), semi-skilled (SVP 3-4), and skilled (SVP 5-9) work. Evaluates transferability of skills to other occupations requiring similar skills and minimal vocational adjustment. Work experience is one of the four vocational factors that interact with RFC in the Grid Rules.";

MERGE (cfr_1563:Regulation:LegalSource {id: "cfr_404-1563"})
SET cfr_1563.section        = "404.1563",
    cfr_1563.title          = "Your Age as a Vocational Factor",
    cfr_1563.code           = "20 C.F.R.",
    cfr_1563.cfr_cite       = "20 C.F.R. § 404.1563",
    cfr_1563.jurisdiction   = "US",
    cfr_1563.source_type    = "regulation",
    cfr_1563.current_status = "active",
    cfr_1563.summary        = "Establishes SSA age categories used in vocational analysis: younger individual (under 50); closely approaching advanced age (50-54); advanced age (55-59); closely approaching retirement age (60-64). SSA may find a claimant in one category is in the next older category if it benefits them. Age is a proxy for adaptability to new types of work — the older the claimant, the more difficulty adapting to new occupational demands.";

MERGE (cfr_1564:Regulation:LegalSource {id: "cfr_404-1564"})
SET cfr_1564.section        = "404.1564",
    cfr_1564.title          = "Your Education as a Vocational Factor",
    cfr_1564.code           = "20 C.F.R.",
    cfr_1564.cfr_cite       = "20 C.F.R. § 404.1564",
    cfr_1564.jurisdiction   = "US",
    cfr_1564.source_type    = "regulation",
    cfr_1564.current_status = "active",
    cfr_1564.summary        = "Establishes education categories: illiteracy; marginal education (6th grade or less); limited education (7th-11th grade); high school graduate or more; direct entry into skilled work (education that provides for direct entry into skilled work). Education level relates to claimant's ability to perform mental work activities and adaptability to new work. Higher education generally means greater vocational adaptability.";

MERGE (cfr_1565:Regulation:LegalSource {id: "cfr_404-1565"})
SET cfr_1565.section        = "404.1565",
    cfr_1565.title          = "Your Work Experience",
    cfr_1565.code           = "20 C.F.R.",
    cfr_1565.cfr_cite       = "20 C.F.R. § 404.1565",
    cfr_1565.jurisdiction   = "US",
    cfr_1565.source_type    = "regulation",
    cfr_1565.current_status = "active",
    cfr_1565.summary        = "Defines past relevant work (PRW) and its use in disability determination. PRW is work performed in the last 15 years, at SGA level, for sufficient duration to learn the job. Considers whether claimant can perform PRW as actually performed or as generally performed in the national economy. Unskilled work requires 30 days or less to learn; skilled work may require years.";

MERGE (cfr_1566:Regulation:LegalSource {id: "cfr_404-1566"})
SET cfr_1566.section        = "404.1566",
    cfr_1566.title          = "Work Which Exists in Significant Numbers in the National Economy",
    cfr_1566.code           = "20 C.F.R.",
    cfr_1566.cfr_cite       = "20 C.F.R. § 404.1566",
    cfr_1566.jurisdiction   = "US",
    cfr_1566.source_type    = "regulation",
    cfr_1566.current_status = "active",
    cfr_1566.summary        = "Defines what constitutes 'significant numbers' of jobs in the national economy at Step 5. SSA considers jobs in the national economy as a whole rather than a specific region. Work exists in significant numbers even if not available in claimant's immediate area or if claimant cannot be hired for other reasons (e.g., past record). May use DOT, Census data, occupational surveys, or VE/VS testimony as evidence of job numbers.";


// --- INTERPRETS edges (SSR → CFR Regulation) ---

// SSR 96-8p → RFC assessment regulation
MATCH (ssr:SSR {id: "ssr_96-8p"})
MATCH (reg:Regulation {id: "cfr_404-1545"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 96-8p provides detailed operational guidance for conducting the RFC assessment required by this regulation, including the function-by-function assessment methodology"
}]->(reg);

// SSR 00-4p → occupational evidence / significant jobs regulation
MATCH (ssr:SSR {id: "ssr_00-4p"})
MATCH (reg:Regulation {id: "cfr_404-1566"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 00-4p governs use of VE testimony and DOT consistency requirements when establishing jobs exist in significant numbers under this regulation"
}]->(reg);

// SSR 83-10 → vocational factors framework
MATCH (ssr:SSR {id: "ssr_83-10"})
MATCH (reg:Regulation {id: "cfr_404-1560"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 83-10 defines the exertional level categories and Grid Rule framework used in the vocational analysis conducted under this regulation"
}]->(reg);

// SSR 85-15 → vocational factors for nonexertional-only claimants
MATCH (ssr:SSR {id: "ssr_85-15"})
MATCH (reg:Regulation {id: "cfr_404-1560"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 85-15 provides the framework for applying vocational factors when the claimant's limitations are solely nonexertional — Grid Rules cannot be used directly in this scenario"
}]->(reg);

// SSR 82-41 → work experience regulation
MATCH (ssr:SSR {id: "ssr_82-41"})
MATCH (reg:Regulation {id: "cfr_404-1565"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 82-41 operationalizes the work experience vocational factor, defining PRW, skill levels, and transferability analysis under this regulation"
}]->(reg);

// SSR 16-3p → sequential evaluation (symptom evaluation applied throughout Steps 2–5)
MATCH (ssr:SSR {id: "ssr_16-3p"})
MATCH (reg:Regulation {id: "cfr_404-1520"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 16-3p governs how symptom evaluation is conducted within the sequential evaluation framework — relevant at Steps 2 (severity), 3 (listings), 4 (PRW), and 5 (other work)"
}]->(reg);

// SSR 96-9p → RFC regulation (sedentary erosion analysis)
MATCH (ssr:SSR {id: "ssr_96-9p"})
MATCH (reg:Regulation {id: "cfr_404-1545"})
MERGE (ssr)-[:INTERPRETS {
    relationship: "SSR 96-9p interprets the RFC regulation specifically for claimants with less-than-full-range sedentary RFC, addressing how nonexertional limitations further erode the occupational base"
}]->(reg);


// ============================================================================
// SECTION 1.5.5: SUPPORTING CHAIN NODES
// ============================================================================
// Required for AC1: full traversable medical-vocational chain
//   MedicalCondition → FunctionalLimitation → RFCComponent
//   → WorkLevel → GridRule → EvaluationOutcome
// ============================================================================

// --- FunctionalLimitation nodes ---

MERGE (fl_standing:FunctionalLimitation {id: "fl_limited_standing_walking"})
SET fl_standing.name        = "Limited Standing and Walking",
    fl_standing.category    = "exertional",
    fl_standing.ssa_domain  = "physical",
    fl_standing.description = "Inability to stand and/or walk for more than 2 hours in an 8-hour workday; consistent with sedentary exertional level per SSR 83-10";

MERGE (fl_lifting:FunctionalLimitation {id: "fl_limited_lifting_carrying"})
SET fl_lifting.name         = "Limited Lifting and Carrying",
    fl_lifting.category     = "exertional",
    fl_lifting.ssa_domain   = "physical",
    fl_lifting.description  = "Unable to lift more than 10 lbs occasionally and less than 10 lbs frequently; upper end of sedentary RFC per 20 C.F.R. § 404.1567(a)";

MERGE (fl_sitting:FunctionalLimitation {id: "fl_limited_sitting"})
SET fl_sitting.name         = "Limited Sitting Tolerance",
    fl_sitting.category     = "exertional",
    fl_sitting.ssa_domain   = "physical",
    fl_sitting.description  = "Cannot sit for more than 6 hours in an 8-hour workday without the option to alternate positions; may erode even sedentary occupational base per SSR 96-9p";

MERGE (fl_cpp:FunctionalLimitation {id: "fl_limited_cpp"})
SET fl_cpp.name             = "Limited Concentration, Persistence, and Pace",
    fl_cpp.category         = "nonexertional",
    fl_cpp.ssa_domain       = "mental",
    fl_cpp.description      = "Marked limitation in ability to maintain attention and concentration for extended periods, to complete tasks in a timely manner, or to perform at a consistent pace without unreasonable rest periods; Paragraph B area 3 under 12.xx listings";

MERGE (fl_social:FunctionalLimitation {id: "fl_limited_social_interaction"})
SET fl_social.name          = "Limited Social Interaction",
    fl_social.category      = "nonexertional",
    fl_social.ssa_domain    = "mental",
    fl_social.description   = "Marked limitation in ability to interact appropriately with supervisors, co-workers, and/or the public in a workplace setting; Paragraph B area 2 under 12.xx listings";

MERGE (fl_adaptation:FunctionalLimitation {id: "fl_limited_adaptation"})
SET fl_adaptation.name      = "Limited Adaptation to Changes",
    fl_adaptation.category  = "nonexertional",
    fl_adaptation.ssa_domain = "mental",
    fl_adaptation.description = "Marked limitation in ability to respond appropriately to ordinary work pressures, adapt to changes in routine work settings, or maintain regular attendance without unreasonable absences; Paragraph B area 4 under 12.xx listings";


// --- RFCComponent nodes (five exertional levels) ---

MERGE (rfc_sedentary:RFCComponent {id: "rfc_sedentary"})
SET rfc_sedentary.name                  = "Sedentary RFC",
    rfc_sedentary.exertional_level      = "sedentary",
    rfc_sedentary.max_lift_occasional   = 10,
    rfc_sedentary.max_lift_frequent     = 5,
    rfc_sedentary.standing_walking_hrs  = 2,
    rfc_sedentary.sitting_hrs           = 6,
    rfc_sedentary.cfr_cite              = "20 C.F.R. § 404.1567(a)",
    rfc_sedentary.description           = "Sedentary work: lifting no more than 10 lbs at a time, occasional lifting/carrying of articles like docket files, ledgers, and small tools. Primarily sitting; occasional walking and standing.";

MERGE (rfc_light:RFCComponent {id: "rfc_light"})
SET rfc_light.name                  = "Light RFC",
    rfc_light.exertional_level      = "light",
    rfc_light.max_lift_occasional   = 20,
    rfc_light.max_lift_frequent     = 10,
    rfc_light.standing_walking_hrs  = 6,
    rfc_light.sitting_hrs           = 6,
    rfc_light.cfr_cite              = "20 C.F.R. § 404.1567(b)",
    rfc_light.description           = "Light work: lifting up to 20 lbs occasionally and 10 lbs frequently; standing/walking up to 6 hours per 8-hour workday.";

MERGE (rfc_medium:RFCComponent {id: "rfc_medium"})
SET rfc_medium.name                 = "Medium RFC",
    rfc_medium.exertional_level     = "medium",
    rfc_medium.max_lift_occasional  = 50,
    rfc_medium.max_lift_frequent    = 25,
    rfc_medium.standing_walking_hrs = 6,
    rfc_medium.sitting_hrs          = 6,
    rfc_medium.cfr_cite             = "20 C.F.R. § 404.1567(c)",
    rfc_medium.description          = "Medium work: lifting up to 50 lbs occasionally and 25 lbs frequently.";

MERGE (rfc_heavy:RFCComponent {id: "rfc_heavy"})
SET rfc_heavy.name                  = "Heavy RFC",
    rfc_heavy.exertional_level      = "heavy",
    rfc_heavy.max_lift_occasional   = 100,
    rfc_heavy.max_lift_frequent     = 50,
    rfc_heavy.cfr_cite              = "20 C.F.R. § 404.1567(d)",
    rfc_heavy.description           = "Heavy work: lifting up to 100 lbs occasionally and 50 lbs frequently.";

MERGE (rfc_very_heavy:RFCComponent {id: "rfc_very_heavy"})
SET rfc_very_heavy.name                  = "Very Heavy RFC",
    rfc_very_heavy.exertional_level      = "very_heavy",
    rfc_very_heavy.max_lift_occasional   = 9999,
    rfc_very_heavy.max_lift_frequent     = 100,
    rfc_very_heavy.cfr_cite              = "20 C.F.R. § 404.1567(e)",
    rfc_very_heavy.description           = "Very heavy work: lifting objects weighing more than 100 lbs at a time with frequent lifting or carrying of objects weighing 50 lbs or more.";


// --- WorkLevel nodes (mirrors RFC exertional levels) ---

MERGE (wl_sedentary:WorkLevel {id: "wl_sedentary"})
SET wl_sedentary.name        = "Sedentary Work",
    wl_sedentary.level       = "sedentary",
    wl_sedentary.dot_category = "sedentary",
    wl_sedentary.description  = "Primarily sitting; occasional walking/standing; lifting up to 10 lbs";

MERGE (wl_light:WorkLevel {id: "wl_light"})
SET wl_light.name            = "Light Work",
    wl_light.level           = "light",
    wl_light.dot_category    = "light",
    wl_light.description     = "Standing/walking up to 6 hours; lifting up to 20 lbs occasionally";

MERGE (wl_medium:WorkLevel {id: "wl_medium"})
SET wl_medium.name           = "Medium Work",
    wl_medium.level          = "medium",
    wl_medium.dot_category   = "medium",
    wl_medium.description    = "Lifting up to 50 lbs; standing/walking most of the workday";

MERGE (wl_heavy:WorkLevel {id: "wl_heavy"})
SET wl_heavy.name            = "Heavy Work",
    wl_heavy.level           = "heavy",
    wl_heavy.dot_category    = "heavy",
    wl_heavy.description     = "Lifting up to 100 lbs; very demanding physical exertion";

MERGE (wl_very_heavy:WorkLevel {id: "wl_very_heavy"})
SET wl_very_heavy.name       = "Very Heavy Work",
    wl_very_heavy.level      = "very_heavy",
    wl_very_heavy.dot_category = "very_heavy",
    wl_very_heavy.description = "Lifting over 100 lbs; extreme physical demands";


// --- GridRule nodes (representative rules, 20 C.F.R. Part 404, Subpart P, Appendix 2) ---

MERGE (gr_201_14:GridRule {id: "gr_201_14"})
SET gr_201_14.rule_number     = "201.14",
    gr_201_14.rfc_level       = "sedentary",
    gr_201_14.age_category    = "closely_approaching_advanced_age",
    gr_201_14.education       = "high_school_no_direct_entry",
    gr_201_14.work_experience = "unskilled_or_none",
    gr_201_14.decision        = "disabled",
    gr_201_14.cfr_cite        = "20 C.F.R. Part 404, Subpart P, Appendix 2, Table 1, Rule 201.14",
    gr_201_14.description     = "Sedentary RFC, age 50-54, HS education or more (not direct entry into skilled work), unskilled or no prior work → Disabled";

MERGE (gr_201_28:GridRule {id: "gr_201_28"})
SET gr_201_28.rule_number     = "201.28",
    gr_201_28.rfc_level       = "sedentary",
    gr_201_28.age_category    = "younger_individual",
    gr_201_28.education       = "high_school_or_more",
    gr_201_28.work_experience = "unskilled_or_none",
    gr_201_28.decision        = "not_disabled",
    gr_201_28.cfr_cite        = "20 C.F.R. Part 404, Subpart P, Appendix 2, Table 1, Rule 201.28",
    gr_201_28.description     = "Sedentary RFC, younger individual (under 50), HS education or more, unskilled or no prior work → Not Disabled";

MERGE (gr_202_06:GridRule {id: "gr_202_06"})
SET gr_202_06.rule_number     = "202.06",
    gr_202_06.rfc_level       = "light",
    gr_202_06.age_category    = "advanced_age",
    gr_202_06.education       = "high_school_no_direct_entry",
    gr_202_06.work_experience = "skilled_semi_skilled_no_transferable",
    gr_202_06.decision        = "disabled",
    gr_202_06.cfr_cite        = "20 C.F.R. Part 404, Subpart P, Appendix 2, Table 2, Rule 202.06",
    gr_202_06.description     = "Light RFC, advanced age (55+), HS education or more (not direct entry), skilled/semi-skilled with no transferable skills → Disabled";

MERGE (gr_203_14:GridRule {id: "gr_203_14"})
SET gr_203_14.rule_number     = "203.14",
    gr_203_14.rfc_level       = "medium",
    gr_203_14.age_category    = "closely_approaching_advanced_age",
    gr_203_14.education       = "limited_or_less",
    gr_203_14.work_experience = "unskilled_or_none",
    gr_203_14.decision        = "disabled",
    gr_203_14.cfr_cite        = "20 C.F.R. Part 404, Subpart P, Appendix 2, Table 3, Rule 203.14",
    gr_203_14.description     = "Medium RFC, age 50-54, limited education or less, unskilled or no prior work → Disabled";


// ============================================================================
// SECTION 1.5.6: WIRE THE MEDICAL-VOCATIONAL CHAIN
// ============================================================================
// Relationship types:
//   CAUSES_LIMITATION      MedicalCondition    → FunctionalLimitation
//   MAPS_TO_RFC            FunctionalLimitation → RFCComponent
//   DETERMINES_WORK_LEVEL  RFCComponent         → WorkLevel
//   GOVERNS                WorkLevel            → GridRule
//   RESULTS_IN             GridRule             → EvaluationOutcome
// ============================================================================

// --- CAUSES_LIMITATION: MedicalCondition → FunctionalLimitation ---

MATCH (mc:MedicalCondition {id: "mc_degenerative_disc_disease"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_degenerative_disc_disease"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_lifting_carrying"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_lumbar_spinal_stenosis"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_knee"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_osteoarthritis_hip"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_fibromyalgia"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_fibromyalgia"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_cpp"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_rotator_cuff_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_lifting_carrying"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_major_depressive_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_cpp"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_major_depressive_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_adaptation"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_ptsd"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_social_interaction"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_ptsd"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_adaptation"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_schizophrenia"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_cpp"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_schizophrenia"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_social_interaction"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_generalized_anxiety_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_cpp"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_bipolar_i_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_adaptation"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);

MATCH (mc:MedicalCondition {id: "mc_panic_disorder"})
MATCH (fl:FunctionalLimitation {id: "fl_limited_social_interaction"})
MERGE (mc)-[:CAUSES_LIMITATION]->(fl);


// --- MAPS_TO_RFC: FunctionalLimitation → RFCComponent ---

MATCH (fl:FunctionalLimitation {id: "fl_limited_standing_walking"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "Inability to stand/walk more than 2 hours per SSR 83-10 restricts claimant to sedentary exertional level"
}]->(rfc);

MATCH (fl:FunctionalLimitation {id: "fl_limited_lifting_carrying"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "Max lift of 10 lbs or less falls within the sedentary RFC range per 20 C.F.R. § 404.1567(a)"
}]->(rfc);

MATCH (fl:FunctionalLimitation {id: "fl_limited_sitting"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "Sitting limitation may erode the sedentary occupational base per SSR 96-9p; RFC is sedentary level with additional restrictions"
}]->(rfc);

MATCH (fl:FunctionalLimitation {id: "fl_limited_cpp"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "CPP is a nonexertional limitation; sedentary RFC is the most common exertional level paired with mental limitations (per SSR 85-15)"
}]->(rfc);

MATCH (fl:FunctionalLimitation {id: "fl_limited_social_interaction"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "Social limitation is nonexertional; RFC includes mental restrictions on public/coworker contact that apply across any exertional level"
}]->(rfc);

MATCH (fl:FunctionalLimitation {id: "fl_limited_adaptation"})
MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MERGE (fl)-[:MAPS_TO_RFC {
    rationale: "Adaptation limitation is nonexertional; restricts work complexity and tolerance for change within RFC — typically limits to simple, routine tasks"
}]->(rfc);


// --- DETERMINES_WORK_LEVEL: RFCComponent → WorkLevel ---

MATCH (rfc:RFCComponent {id: "rfc_sedentary"})
MATCH (wl:WorkLevel {id: "wl_sedentary"})
MERGE (rfc)-[:DETERMINES_WORK_LEVEL]->(wl);

MATCH (rfc:RFCComponent {id: "rfc_light"})
MATCH (wl:WorkLevel {id: "wl_light"})
MERGE (rfc)-[:DETERMINES_WORK_LEVEL]->(wl);

MATCH (rfc:RFCComponent {id: "rfc_medium"})
MATCH (wl:WorkLevel {id: "wl_medium"})
MERGE (rfc)-[:DETERMINES_WORK_LEVEL]->(wl);

MATCH (rfc:RFCComponent {id: "rfc_heavy"})
MATCH (wl:WorkLevel {id: "wl_heavy"})
MERGE (rfc)-[:DETERMINES_WORK_LEVEL]->(wl);

MATCH (rfc:RFCComponent {id: "rfc_very_heavy"})
MATCH (wl:WorkLevel {id: "wl_very_heavy"})
MERGE (rfc)-[:DETERMINES_WORK_LEVEL]->(wl);


// --- GOVERNS: WorkLevel → GridRule ---

MATCH (wl:WorkLevel {id: "wl_sedentary"})
MATCH (gr:GridRule {id: "gr_201_14"})
MERGE (wl)-[:GOVERNS]->(gr);

MATCH (wl:WorkLevel {id: "wl_sedentary"})
MATCH (gr:GridRule {id: "gr_201_28"})
MERGE (wl)-[:GOVERNS]->(gr);

MATCH (wl:WorkLevel {id: "wl_light"})
MATCH (gr:GridRule {id: "gr_202_06"})
MERGE (wl)-[:GOVERNS]->(gr);

MATCH (wl:WorkLevel {id: "wl_medium"})
MATCH (gr:GridRule {id: "gr_203_14"})
MERGE (wl)-[:GOVERNS]->(gr);


// --- RESULTS_IN: GridRule → EvaluationOutcome ---
// EvaluationOutcome nodes created in load_evaluation_steps.cypher (Task 1.4)

MATCH (gr:GridRule {id: "gr_201_14"})
MATCH (eo:EvaluationOutcome {id: "outcome_disabled"})
MERGE (gr)-[:RESULTS_IN]->(eo);

MATCH (gr:GridRule {id: "gr_201_28"})
MATCH (eo:EvaluationOutcome {id: "outcome_not_disabled"})
MERGE (gr)-[:RESULTS_IN]->(eo);

MATCH (gr:GridRule {id: "gr_202_06"})
MATCH (eo:EvaluationOutcome {id: "outcome_disabled"})
MERGE (gr)-[:RESULTS_IN]->(eo);

MATCH (gr:GridRule {id: "gr_203_14"})
MATCH (eo:EvaluationOutcome {id: "outcome_disabled"})
MERGE (gr)-[:RESULTS_IN]->(eo);


// ============================================================================
// SECTION 1.5.7: EVIDENCE TYPE NODES + REQUIRES_EVIDENCE EDGES
// ============================================================================
// 12 EvidenceType nodes covering both musculoskeletal and mental health
// listing requirements.
// REQUIRES_EVIDENCE edges wire Listings to the evidence types they mandate.
// ============================================================================

// --- EvidenceType nodes ---

MERGE (et_treating:EvidenceType {id: "et_treating_source_opinion"})
SET et_treating.name        = "Treating Source Opinion",
    et_treating.description = "Medical opinion from a treating physician, psychiatrist, or other acceptable medical source regarding diagnosis, prognosis, and functional limitations",
    et_treating.ssa_weight  = "Highest weight — controlling weight if well-supported and not inconsistent with other substantial evidence (SSR 96-2p)";

MERGE (et_imaging:EvidenceType {id: "et_imaging_study"})
SET et_imaging.name         = "Imaging Study",
    et_imaging.description  = "X-ray, MRI, CT scan, or other medically acceptable imaging showing structural abnormalities relevant to the claimed impairment",
    et_imaging.ssa_weight   = "Objective medical evidence; required for most musculoskeletal listings";

MERGE (et_mri_ct:EvidenceType {id: "et_mri_or_ct_imaging"})
SET et_mri_ct.name          = "MRI or CT Imaging",
    et_mri_ct.description   = "Advanced cross-sectional imaging specifically required for spine and nerve root compromise listings (1.04, 1.15, 1.16)",
    et_mri_ct.ssa_weight    = "Required objective medical evidence — listings 1.04, 1.15, and 1.16 explicitly require findings on medically acceptable imaging";

MERGE (et_psx:EvidenceType {id: "et_physical_examination_findings"})
SET et_psx.name             = "Physical Examination Findings",
    et_psx.description      = "Documented findings from clinical physical examination including range of motion measurements, muscle strength testing, neurological signs, and gait assessment",
    et_psx.ssa_weight       = "Objective clinical evidence required for all musculoskeletal listings";

MERGE (et_fce:EvidenceType {id: "et_functional_capacity_evaluation"})
SET et_fce.name             = "Functional Capacity Evaluation",
    et_fce.description      = "Formal standardized assessment of claimant's physical functional capacity including lifting, carrying, sitting, standing, and walking tolerances conducted by physical or occupational therapist",
    et_fce.ssa_weight       = "Supporting evidence for RFC assessment; particularly relevant for Listing 1.16 cauda equina compromise";

MERGE (et_op_report:EvidenceType {id: "et_operative_report"})
SET et_op_report.name       = "Operative Report",
    et_op_report.description = "Surgical notes and operative reports documenting procedures performed, intraoperative findings, and post-operative status",
    et_op_report.ssa_weight  = "Required objective evidence for Listing 1.17 — reconstructive surgery or surgical arthrodesis must be documented by operative report";

MERGE (et_psych_eval:EvidenceType {id: "et_psychiatric_evaluation"})
SET et_psych_eval.name      = "Psychiatric Evaluation",
    et_psych_eval.description = "Comprehensive psychiatric evaluation by psychiatrist or licensed psychologist documenting mental status examination findings, diagnosis, and functional impact on work-related activities",
    et_psych_eval.ssa_weight = "Primary evidence for 12.xx mental health listings; should include Paragraph A diagnostic criteria and Paragraph B functional ratings";

MERGE (et_mse:EvidenceType {id: "et_mental_status_examination"})
SET et_mse.name             = "Mental Status Examination",
    et_mse.description      = "Structured clinical assessment of orientation, memory, attention, thought process, thought content, perceptual disturbances, affect, mood, insight, and judgment",
    et_mse.ssa_weight       = "Objective clinical evidence for all 12.xx listings; documents the specific Paragraph A symptoms and Paragraph B functional limitations";

MERGE (et_psych_testing:EvidenceType {id: "et_psychological_testing"})
SET et_psych_testing.name   = "Psychological Testing",
    et_psych_testing.description = "Standardized neuropsychological or psychological testing (e.g., MMPI-2, Wechsler Adult Intelligence Scale, Beck Depression Inventory) documenting cognitive and psychological functioning",
    et_psych_testing.ssa_weight  = "Supporting objective evidence for 12.04 and related listings; useful for establishing Paragraph B functional limitations with objective data";

MERGE (et_trauma_hx:EvidenceType {id: "et_trauma_history_documentation"})
SET et_trauma_hx.name       = "Trauma History Documentation",
    et_trauma_hx.description = "Documented history of exposure to actual or threatened death, violence, or serious injury — required foundational evidence for PTSD and trauma-related disorder listings",
    et_trauma_hx.ssa_weight  = "Required Paragraph A evidence for Listing 12.15 — must document exposure to qualifying traumatic event(s)";

MERGE (et_inpatient:EvidenceType {id: "et_inpatient_records"})
SET et_inpatient.name       = "Inpatient Psychiatric Records",
    et_inpatient.description = "Records from inpatient psychiatric hospitalizations documenting acute episodes, treatment provided, response to treatment, and discharge baseline functioning",
    et_inpatient.ssa_weight  = "Strong supporting evidence for 12.03 schizophrenia spectrum disorders; documents severity of positive symptoms and need for intensive treatment";

MERGE (et_ncs:EvidenceType {id: "et_nerve_conduction_study"})
SET et_ncs.name             = "Nerve Conduction Study / EMG",
    et_ncs.description      = "Electromyography (EMG) and nerve conduction velocity (NCV) studies documenting peripheral nerve damage, radiculopathy, or denervation consistent with nerve root compromise",
    et_ncs.ssa_weight       = "Objective evidence relevant to Listing 1.04 nerve root compression; documents neurophysiological correlates of anatomical findings";


// --- REQUIRES_EVIDENCE edges (Listing → EvidenceType) ---

// Listing 1.02
MATCH (l:Listing {id: "listing_1_02"})
MATCH (et:EvidenceType {id: "et_imaging_study"})            MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_02"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})  MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_02"})
MATCH (et:EvidenceType {id: "et_physical_examination_findings"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 1.04
MATCH (l:Listing {id: "listing_1_04"})
MATCH (et:EvidenceType {id: "et_mri_or_ct_imaging"})        MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_04"})
MATCH (et:EvidenceType {id: "et_nerve_conduction_study"})   MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_04"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})  MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 1.15
MATCH (l:Listing {id: "listing_1_15"})
MATCH (et:EvidenceType {id: "et_mri_or_ct_imaging"})             MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_15"})
MATCH (et:EvidenceType {id: "et_physical_examination_findings"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_15"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})       MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 1.16
MATCH (l:Listing {id: "listing_1_16"})
MATCH (et:EvidenceType {id: "et_mri_or_ct_imaging"})             MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_16"})
MATCH (et:EvidenceType {id: "et_physical_examination_findings"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_16"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})       MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_16"})
MATCH (et:EvidenceType {id: "et_functional_capacity_evaluation"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 1.17
MATCH (l:Listing {id: "listing_1_17"})
MATCH (et:EvidenceType {id: "et_operative_report"})         MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_17"})
MATCH (et:EvidenceType {id: "et_imaging_study"})            MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_17"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})  MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 1.18
MATCH (l:Listing {id: "listing_1_18"})
MATCH (et:EvidenceType {id: "et_imaging_study"})                  MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_18"})
MATCH (et:EvidenceType {id: "et_physical_examination_findings"})  MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_1_18"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})        MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 12.03
MATCH (l:Listing {id: "listing_12_03"})
MATCH (et:EvidenceType {id: "et_psychiatric_evaluation"})    MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_03"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})   MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_03"})
MATCH (et:EvidenceType {id: "et_mental_status_examination"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_03"})
MATCH (et:EvidenceType {id: "et_inpatient_records"})         MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 12.04
MATCH (l:Listing {id: "listing_12_04"})
MATCH (et:EvidenceType {id: "et_psychiatric_evaluation"})    MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_04"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})   MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_04"})
MATCH (et:EvidenceType {id: "et_mental_status_examination"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_04"})
MATCH (et:EvidenceType {id: "et_psychological_testing"})     MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 12.06
MATCH (l:Listing {id: "listing_12_06"})
MATCH (et:EvidenceType {id: "et_psychiatric_evaluation"})    MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_06"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})   MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_06"})
MATCH (et:EvidenceType {id: "et_mental_status_examination"}) MERGE (l)-[:REQUIRES_EVIDENCE]->(et);

// Listing 12.15
MATCH (l:Listing {id: "listing_12_15"})
MATCH (et:EvidenceType {id: "et_psychiatric_evaluation"})         MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_15"})
MATCH (et:EvidenceType {id: "et_treating_source_opinion"})        MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_15"})
MATCH (et:EvidenceType {id: "et_mental_status_examination"})      MERGE (l)-[:REQUIRES_EVIDENCE]->(et);
MATCH (l:Listing {id: "listing_12_15"})
MATCH (et:EvidenceType {id: "et_trauma_history_documentation"})   MERGE (l)-[:REQUIRES_EVIDENCE]->(et);


// ============================================================================
// VERIFICATION QUERIES
// ============================================================================
// Run these after loading to confirm expected node and relationship counts.
// ============================================================================

// --- Node counts ---
MATCH (mc:MedicalCondition)  RETURN count(mc)  AS medical_condition_count;  // Expected: 12
MATCH (l:Listing)            RETURN count(l)   AS listing_count;             // Expected: 10
MATCH (ssr:SSR)              RETURN count(ssr) AS ssr_count;                 // Expected: 12
MATCH (r:Regulation)         RETURN count(r)   AS regulation_count;          // Expected: 8
MATCH (et:EvidenceType)      RETURN count(et)  AS evidence_type_count;       // Expected: 12
MATCH (fl:FunctionalLimitation) RETURN count(fl) AS functional_limitation_count; // Expected: 6
MATCH (rfc:RFCComponent)     RETURN count(rfc) AS rfc_component_count;       // Expected: 5
MATCH (wl:WorkLevel)         RETURN count(wl)  AS work_level_count;          // Expected: 5
MATCH (gr:GridRule)          RETURN count(gr)  AS grid_rule_count;           // Expected: 4

// --- AC1: Full medical-vocational chain traversal ---
MATCH path =
    (mc:MedicalCondition {id: "mc_degenerative_disc_disease"})
    -[:CAUSES_LIMITATION]->(fl:FunctionalLimitation)
    -[:MAPS_TO_RFC]->(rfc:RFCComponent)
    -[:DETERMINES_WORK_LEVEL]->(wl:WorkLevel)
    -[:GOVERNS]->(gr:GridRule)
    -[:RESULTS_IN]->(outcome:EvaluationOutcome)
RETURN
    mc.name        AS condition,
    fl.name        AS limitation,
    rfc.name       AS rfc_level,
    wl.name        AS work_level,
    gr.rule_number AS grid_rule,
    outcome.result AS decision
LIMIT 5;
// Expected: rows showing DDD → limited standing → sedentary RFC → sedentary work → grid rules → disabled/not_disabled

// --- AC2: Listing evidence gap query ---
MATCH (mc:MedicalCondition)-[:MAY_MEET_LISTING]->(l:Listing)-[:REQUIRES_EVIDENCE]->(et:EvidenceType)
RETURN
    mc.name   AS condition,
    l.section AS listing,
    collect(et.name) AS required_evidence
ORDER BY mc.name, l.section;
// Expected: rows for each condition-listing pair with their evidence requirements

// --- AC3: SSR supersedes chain ---
MATCH path = (new_ssr:SSR {number: "16-3p"})-[:SUPERSEDES*1..3]->(old_ssr:SSR {number: "96-7p"})
RETURN
    length(path)        AS chain_length,
    new_ssr.number      AS superseding_ssr,
    new_ssr.title       AS superseding_title,
    old_ssr.number      AS superseded_ssr,
    old_ssr.current_status AS superseded_status;
// Expected: chain_length=1, superseding_ssr="16-3p", superseded_ssr="96-7p", superseded_status="superseded"
