// ============================================================================
// UNIQUENESS CONSTRAINTS
// ============================================================================

CREATE CONSTRAINT case_id_unique IF NOT EXISTS
FOR (c:Case) REQUIRE c.id IS UNIQUE;

CREATE CONSTRAINT statute_id_unique IF NOT EXISTS
FOR (s:Statute) REQUIRE s.id IS UNIQUE;

CREATE CONSTRAINT regulation_id_unique IF NOT EXISTS
FOR (r:Regulation) REQUIRE r.id IS UNIQUE;

CREATE CONSTRAINT court_id_unique IF NOT EXISTS
FOR (court:Court) REQUIRE court.id IS UNIQUE;

CREATE CONSTRAINT jurisdiction_id_unique IF NOT EXISTS
FOR (j:Jurisdiction) REQUIRE j.id IS UNIQUE;

CREATE CONSTRAINT concept_id_unique IF NOT EXISTS
FOR (lc:LegalConcept) REQUIRE lc.id IS UNIQUE;

CREATE CONSTRAINT matter_id_unique IF NOT EXISTS
FOR (m:Matter) REQUIRE m.id IS UNIQUE;

CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.id IS UNIQUE;


// ============================================================================
// EXISTENCE CONSTRAINTS
// ============================================================================

CREATE CONSTRAINT case_citation_required IF NOT EXISTS
FOR (c:Case) REQUIRE c.citation IS NOT NULL;

CREATE CONSTRAINT source_type_required IF NOT EXISTS
FOR (s:LegalSource) REQUIRE s.source_type IS NOT NULL;

CREATE CONSTRAINT source_jurisdiction_required IF NOT EXISTS
FOR (s:LegalSource) REQUIRE s.jurisdiction IS NOT NULL;

CREATE CONSTRAINT source_status_required IF NOT EXISTS
FOR (s:LegalSource) REQUIRE s.current_status IS NOT NULL;


// ============================================================================
// FULL-TEXT SEARCH INDEXES
// ============================================================================

CREATE FULLTEXT INDEX case_fulltext_index IF NOT EXISTS
FOR (c:Case) 
ON EACH [c.title, c.summary, c.holding];

CREATE FULLTEXT INDEX statute_fulltext_index IF NOT EXISTS
FOR (s:Statute) 
ON EACH [s.title, s.text, s.section];

CREATE FULLTEXT INDEX concept_fulltext_index IF NOT EXISTS
FOR (lc:LegalConcept) 
ON EACH [lc.name, lc.description];


// ============================================================================
// PROPERTY INDEXES
// ============================================================================

CREATE INDEX case_date_index IF NOT EXISTS
FOR (c:Case) ON (c.decision_date);

CREATE INDEX source_jurisdiction_index IF NOT EXISTS
FOR (s:LegalSource) ON (s.jurisdiction);

CREATE INDEX source_status_index IF NOT EXISTS
FOR (s:LegalSource) ON (s.current_status);

CREATE INDEX source_type_index IF NOT EXISTS
FOR (s:LegalSource) ON (s.source_type);

CREATE INDEX case_precedential_index IF NOT EXISTS
FOR (c:Case) ON (c.precedential_value);

CREATE INDEX case_court_level_index IF NOT EXISTS
FOR (c:Case) ON (c.court_level);

CREATE INDEX statute_section_index IF NOT EXISTS
FOR (s:Statute) ON (s.section);


// ============================================================================
// SSDI DOMAIN — UNIQUENESS CONSTRAINTS (Task 1.2.1)
// ============================================================================

CREATE CONSTRAINT medical_condition_id_unique IF NOT EXISTS
FOR (mc:MedicalCondition) REQUIRE mc.id IS UNIQUE;

CREATE CONSTRAINT listing_id_unique IF NOT EXISTS
FOR (l:Listing) REQUIRE l.id IS UNIQUE;

CREATE CONSTRAINT ssr_id_unique IF NOT EXISTS
FOR (ssr:SSR) REQUIRE ssr.id IS UNIQUE;

CREATE CONSTRAINT rfc_component_id_unique IF NOT EXISTS
FOR (rfc:RFCComponent) REQUIRE rfc.id IS UNIQUE;

CREATE CONSTRAINT occupation_id_unique IF NOT EXISTS
FOR (o:Occupation) REQUIRE o.id IS UNIQUE;

CREATE CONSTRAINT grid_rule_id_unique IF NOT EXISTS
FOR (gr:GridRule) REQUIRE gr.id IS UNIQUE;

CREATE CONSTRAINT evaluation_step_id_unique IF NOT EXISTS
FOR (es:EvaluationStep) REQUIRE es.id IS UNIQUE;

CREATE CONSTRAINT evaluation_outcome_id_unique IF NOT EXISTS
FOR (eo:EvaluationOutcome) REQUIRE eo.id IS UNIQUE;

CREATE CONSTRAINT functional_limitation_id_unique IF NOT EXISTS
FOR (fl:FunctionalLimitation) REQUIRE fl.id IS UNIQUE;

CREATE CONSTRAINT claimant_id_unique IF NOT EXISTS
FOR (cl:Claimant) REQUIRE cl.id IS UNIQUE;

CREATE CONSTRAINT court_case_id_unique IF NOT EXISTS
FOR (cc:CourtCase) REQUIRE cc.id IS UNIQUE;

CREATE CONSTRAINT evidence_type_id_unique IF NOT EXISTS
FOR (et:EvidenceType) REQUIRE et.id IS UNIQUE;


// ============================================================================
// SSDI DOMAIN — PROPERTY INDEXES (Task 1.2.2)
// ============================================================================

// B-tree indexes on query-critical lookup properties
CREATE INDEX listing_section_index IF NOT EXISTS
FOR (l:Listing) ON (l.section);

CREATE INDEX ssr_number_index IF NOT EXISTS
FOR (ssr:SSR) ON (ssr.number);

CREATE INDEX occupation_dot_code_index IF NOT EXISTS
FOR (o:Occupation) ON (o.dot_code);

CREATE INDEX medical_condition_icd10_index IF NOT EXISTS
FOR (mc:MedicalCondition) ON (mc.icd10_code);

CREATE INDEX grid_rule_number_index IF NOT EXISTS
FOR (gr:GridRule) ON (gr.rule_number);

// Composite index for Step 5 Grid Rule lookups — all four vocational factors
// EXPLAIN on: MATCH (gr:GridRule {rfc_level:$r, age_category:$a, education:$e, work_experience:$w})
CREATE INDEX grid_rule_step5_composite_index IF NOT EXISTS
FOR (gr:GridRule) ON (gr.rfc_level, gr.age_category, gr.education, gr.work_experience);


// ============================================================================
// VERIFICATION
// ============================================================================

SHOW CONSTRAINTS;
SHOW INDEXES;

