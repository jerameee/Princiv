// ============================================================================
// BASIC DATA VALIDATION
// ============================================================================

// Query 1: Count all nodes by type
MATCH (n)
RETURN labels(n) as node_type, count(n) as count
ORDER BY count DESC;

// Expected results:
// - LegalSource: 13 (10 cases + 3 statutes)
// - Case: 10
// - Statute: 3
// - Court: 5
// - LegalConcept: 13
// - Jurisdiction: 3


// Query 2: Count all relationship types
MATCH ()-[r]->()
RETURN type(r) as relationship_type, count(r) as count
ORDER BY count DESC;

// Expected relationships:
// - ADDRESSES: ~20
// - SUBCONCEPT_OF: 9
// - DECIDED_BY: 10
// - CITES: ~3-4
// - INTERPRETS: 3
// - OVERRULES: 1
// - DISTINGUISHES: 1


// Query 3: Verify all cases have required properties
MATCH (c:Case)
RETURN 
    c.title,
    c.citation,
    c.decision_date,
    c.jurisdiction,
    c.current_status,
    c.precedential_value
ORDER BY c.decision_date DESC;

// All cases should have these properties populated


// ============================================================================
// JURISDICTIONAL HIERARCHY VALIDATION
// ============================================================================

// Query 4: Find all California Supreme Court cases
MATCH (c:Case)-[:DECIDED_BY]->(court:Court)
WHERE court.id = "ca-supreme"
RETURN c.title, c.citation, c.decision_date
ORDER BY c.decision_date DESC;

// Expected: 7 CA Supreme Court cases


// Query 5: Find all binding precedent in California
MATCH (c:Case)
WHERE c.jurisdiction = "CA"
  AND c.current_status = "active"
  AND c.precedential_value = "binding"
RETURN c.title, c.citation, c.court_level
ORDER BY c.decision_date DESC;

// Should return all CA cases except overruled ones


// Query 6: Verify court hierarchy
MATCH (court:Court)
RETURN 
    court.name,
    court.jurisdiction,
    court.level,
    court.precedential_weight
ORDER BY court.precedential_weight DESC, court.jurisdiction;

// Should show supreme courts with weight 1.0, appellate with 0.9


// ============================================================================
// CITATION ANALYSIS
// ============================================================================

// Query 7: Find all cases that cite other cases
MATCH (citing:Case)-[r:CITES]->(cited:Case)
RETURN 
    citing.title as citing_case,
    cited.title as cited_case,
    r.citation_type as type,
    r.importance as importance
ORDER BY citing.decision_date DESC;

// Should show Carboni citing Donovan, etc.


// Query 8: Find citation chain (cases citing cases that cite others)
MATCH path = (newer:Case)-[:CITES*1..3]->(older:Case)
WHERE newer.id = "carboni-v-arrospide"
RETURN 
    [node in nodes(path) | node.title] as citation_chain,
    length(path) as chain_length;

// Should trace how Carboni connects to earlier cases


// Query 9: Find most cited cases
MATCH (cited:Case)<-[:CITES]-(citing:Case)
RETURN 
    cited.title,
    cited.citation,
    count(citing) as times_cited
ORDER BY times_cited DESC
LIMIT 10;

// Discover Bank and Donovan should appear as heavily cited


// ============================================================================
// TEMPORAL VALIDITY VALIDATION
// ============================================================================

// Query 10: Find overruled cases
MATCH (overruled:Case)
WHERE overruled.current_status = "overruled"
RETURN 
    overruled.title,
    overruled.citation,
    overruled.valid_until,
    overruled.overruled_by;

// Should return Discover Bank overruled by AT&T Mobility


// Query 11: Find overruling relationships
MATCH (newer:Case)-[r:OVERRULES]->(older:Case)
RETURN 
    newer.title as overruling_case,
    older.title as overruled_case,
    r.reasoning as reason;

// Should show AT&T Mobility overruling Discover Bank


// Query 12: Find currently valid cases (exclude overruled)
MATCH (c:Case)
WHERE c.current_status = "active"
  AND c.jurisdiction = "CA"
RETURN 
    c.title,
    c.citation,
    c.decision_date
ORDER BY c.decision_date DESC;

// Should return 9 cases (all except Discover Bank)


// ============================================================================
// LEGAL CONCEPT TAXONOMY VALIDATION
// ============================================================================

// Query 13: Show legal concept hierarchy
MATCH (child:LegalConcept)-[:SUBCONCEPT_OF]->(parent:LegalConcept)
RETURN 
    parent.name as parent_concept,
    collect(child.name) as child_concepts
ORDER BY parent.level;

// Should show Contracts at top, with Formation/Breach/etc as children


// Query 14: Find all cases addressing contract formation
MATCH (c:Case)-[:ADDRESSES]->(concept:LegalConcept)
WHERE concept.id = "contract-formation"
RETURN 
    c.title,
    c.citation,
    c.holding
ORDER BY c.decision_date DESC;

// Should return Donovan and Carboni


// Query 15: Find cases by concept hierarchy (formation and subconcepts)
MATCH (c:Case)-[:ADDRESSES]->(concept:LegalConcept)
MATCH path = (concept)-[:SUBCONCEPT_OF*0..2]->(ancestor:LegalConcept)
WHERE ancestor.id = "contract-formation"
RETURN 
    c.title,
    concept.name as specific_concept,
    ancestor.name as broad_concept
ORDER BY c.decision_date DESC;

// Should show cases about formation, offer, acceptance, consideration


// ============================================================================
// STATUTE-CASE RELATIONSHIPS
// ============================================================================

// Query 16: Find cases interpreting statutes
MATCH (c:Case)-[:INTERPRETS]->(s:Statute)
RETURN 
    c.title as case_title,
    s.section as statute_section,
    s.title as statute_title
ORDER BY s.section;

// Should show Donovan and Carboni interpreting § 1550, etc.


// Query 17: Find all sources addressing a legal concept
MATCH (source:LegalSource)-[:ADDRESSES]->(concept:LegalConcept)
WHERE concept.id = "contract-formation"
RETURN 
    source.source_type as type,
    source.title as title,
    CASE 
        WHEN source.source_type = "case" THEN source.citation
        WHEN source.source_type = "statute" THEN source.section
    END as citation
ORDER BY source.source_type, source.title;

// Should show both Cal. Civ. Code § 1550 AND cases


// ============================================================================
// COMPLEX LEGAL REASONING QUERIES
// ============================================================================

// Query 18: Find binding precedent on a topic in a jurisdiction
MATCH (c:Case)-[:ADDRESSES]->(concept:LegalConcept)
WHERE concept.name CONTAINS "Contract"
  AND c.jurisdiction = "CA"
  AND c.current_status = "active"
  AND c.precedential_value = "binding"
RETURN 
    c.title,
    c.citation,
    c.court_level,
    c.decision_date,
    concept.name as topic
ORDER BY c.court_level DESC, c.decision_date DESC;

// Should prioritize Supreme Court cases over Court of Appeal


// Query 19: Trace legal reasoning from statute to cases
MATCH path = (statute:Statute)<-[:INTERPRETS]-(case1:Case)
OPTIONAL MATCH (case2:Case)-[:CITES]->(case1)
RETURN 
    statute.section as statute,
    case1.title as interpreting_case,
    case1.decision_date as interpretation_date,
    collect(case2.title) as cases_citing_interpretation
ORDER BY case1.decision_date;

// Shows how statutory interpretation propagates through case law


// Query 20: Find related cases via multiple relationship types
MATCH (start:Case {id: "armendariz-v-foundation-health"})
MATCH path = (start)-[*1..2]-(related:Case)
WHERE related.id <> start.id
RETURN DISTINCT
    related.title,
    related.citation,
    [rel in relationships(path) | type(rel)] as relationship_types,
    length(path) as degrees_of_separation
ORDER BY degrees_of_separation, related.decision_date DESC
LIMIT 10;

// Shows network of related cases through various connections


// ============================================================================
// FULL-TEXT SEARCH VALIDATION
// ============================================================================

// Query 21: Full-text search for "unconscionable"
CALL db.index.fulltext.queryNodes("case_fulltext_index", "unconscionable")
YIELD node, score
RETURN 
    node.title,
    node.citation,
    score
ORDER BY score DESC
LIMIT 5;

// Should find Armendariz, Discover Bank cases


// Query 22: Full-text search for "mutual consent"
CALL db.index.fulltext.queryNodes("case_fulltext_index", "mutual consent")
YIELD node, score
RETURN 
    node.title,
    node.citation,
    node.summary,
    score
ORDER BY score DESC
LIMIT 5;

// Should find Donovan and Carboni with high scores


// ============================================================================
// GRAPH STRUCTURE VALIDATION
// ============================================================================

// Query 23: Check for orphaned nodes (nodes with no relationships)
MATCH (n)
WHERE NOT (n)--()
RETURN labels(n) as node_type, n.id as node_id, n.name as node_name;

// Should return nothing - all nodes should be connected


// Query 24: Find most connected nodes (graph centrality)
MATCH (n)
WITH n, size((n)--()) as connection_count
WHERE connection_count > 0
RETURN 
    labels(n) as node_type,
    n.title as title,
    connection_count
ORDER BY connection_count DESC
LIMIT 10;

// Should show key cases and concepts with many connections


// Query 25: Verify bidirectional relationship consistency
// (If A cites B, verify B doesn't also cite A - would be unusual)
MATCH (a:Case)-[:CITES]->(b:Case)
MATCH (b)-[:CITES]->(a)
RETURN a.title, b.title;

// Should return nothing (no circular citations in our data)


// ============================================================================
// PERFORMANCE VALIDATION
// ============================================================================

// Query 26: Test index usage for common query pattern
EXPLAIN
MATCH (c:Case)
WHERE c.jurisdiction = "CA"
  AND c.current_status = "active"
RETURN c.title, c.citation
LIMIT 10;

// Should show index usage (look for "NodeIndexSeek" in plan)


// Query 27: Test full-text search performance
PROFILE
CALL db.index.fulltext.queryNodes("case_fulltext_index", "contract formation")
YIELD node, score
RETURN node.title, score
LIMIT 10;

// Check that db hits are reasonable (should be efficient)


// ============================================================================
// DATA QUALITY CHECKS
// ============================================================================

// Query 28: Find cases missing key properties
MATCH (c:Case)
WHERE c.summary IS NULL 
   OR c.holding IS NULL
   OR c.decision_date IS NULL
RETURN 
    c.title,
    c.citation,
    c.summary IS NULL as missing_summary,
    c.holding IS NULL as missing_holding,
    c.decision_date IS NULL as missing_date;

// Should return nothing - all cases should have these properties


// Query 29: Find cases with invalid dates
MATCH (c:Case)
WHERE c.decision_date > date()
    OR c.decision_date < date("1800-01-01")
RETURN c.title, c.citation, c.decision_date;

// Should return nothing - all dates should be reasonable


// Query 30: Verify jurisdiction consistency
MATCH (c:Case)-[:DECIDED_BY]->(court:Court)
WHERE c.jurisdiction <> court.jurisdiction
RETURN 
    c.title,
    c.jurisdiction as case_jurisdiction,
    court.jurisdiction as court_jurisdiction;

// Should return nothing - jurisdictions should match
// (except federal courts can hear state law cases)


// ============================================================================
// SEQUENTIAL EVALUATION GRAPH VALIDATION (Task 1.4)
// ============================================================================

// Query 31: Acceptance criterion — exactly 5 EvaluationStep nodes
MATCH (e:EvaluationStep) RETURN count(e) AS evaluation_step_count;
// Expected: 5


// Query 32: Verify all steps have required properties
MATCH (e:EvaluationStep)
RETURN
    e.step_number     AS step_number,
    e.name            AS name,
    e.question        AS question,
    e.burden_of_proof AS burden_of_proof,
    e.cfr_cite        AS cfr_cite
ORDER BY e.step_number;
// Expected: 5 rows, each with all properties populated


// Query 33: Acceptance criterion — full five-step path traversable in one query
// This traces the claimant-favored path (no SGA → severe MDI → no listing → no PRW → no other work → disabled)
MATCH path = (s1:EvaluationStep {id: "step_1_sga"})
             -[:IF_NO_GO_TO]->(s2:EvaluationStep)
             -[:IF_YES_GO_TO]->(s3:EvaluationStep)
             -[:IF_NO_GO_TO]->(s4:EvaluationStep)
             -[:IF_NO_GO_TO]->(s5:EvaluationStep)
             -[:IF_NO_GO_TO]->(outcome:EvaluationOutcome)
RETURN
    [n IN nodes(path) | coalesce(n.name, n.result)] AS evaluation_path,
    outcome.result AS final_disposition;
// Expected: single row, final_disposition = "disabled"


// Query 34: Verify all branching edges with their outcome labels
MATCH (e:EvaluationStep)-[r:IF_YES_GO_TO|IF_NO_GO_TO]->(target)
RETURN
    e.step_number                        AS step,
    e.name                               AS step_name,
    type(r)                              AS branch,
    r.outcome                            AS outcome,
    r.disposition                        AS disposition,
    labels(target)                       AS target_type,
    coalesce(target.name, target.result) AS target_name
ORDER BY e.step_number, type(r);
// Expected: 10 rows — 2 edges (IF_YES / IF_NO) per step


// Query 35: Verify Step 3 YES branch terminates at disabled outcome
MATCH (s3:EvaluationStep {id: "step_3_listings"})
      -[r:IF_YES_GO_TO]->(outcome:EvaluationOutcome)
RETURN s3.name AS step, r.outcome AS branch_outcome, outcome.result AS disposition;
// Expected: disposition = "disabled"


// Query 36: Verify Step 5 exhausts into both outcomes
MATCH (s5:EvaluationStep {id: "step_5_other_work"})-[r]->(outcome:EvaluationOutcome)
RETURN type(r) AS branch, r.outcome AS label, outcome.result AS disposition
ORDER BY type(r);
// Expected: 2 rows — IF_YES → not_disabled, IF_NO → disabled


// Query 37: Count all evaluation graph edges
MATCH ()-[r:IF_YES_GO_TO|IF_NO_GO_TO]->() RETURN type(r), count(r) AS count ORDER BY type(r);
// Expected: IF_NO_GO_TO = 5, IF_YES_GO_TO = 5


// ============================================================================
// SUCCESS CRITERIA
// ============================================================================
//
// If all queries run successfully and return expected results:
// ✅ Schema is properly created
// ✅ Data is loaded correctly
// ✅ Relationships are established
// ✅ Indexes are working
// ✅ Graph supports legal reasoning patterns
// ✅ EvaluationStep graph is seeded and traversable (Task 1.4)
// ✅ Ready to proceed with Sprint 2 (retrieval & context assembly)
//
// ============================================================================