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
// VERIFICATION
// ============================================================================

SHOW CONSTRAINTS;
SHOW INDEXES;

