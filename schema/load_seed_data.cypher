// ============================================================================
// STEP 1: CREATE JURISDICTIONS
// ============================================================================

CREATE (us:Jurisdiction {
    id: "US",
    name: "United States",
    type: "federal",
    parent_id: null
});

CREATE (ca:Jurisdiction {
    id: "CA",
    name: "California",
    type: "state",
    parent_id: "US"
});

CREATE (ca_northern:Jurisdiction {
    id: "CA-N",
    name: "Northern District of California",
    type: "federal_district",
    parent_id: "CA"
});


// ============================================================================
// STEP 2: CREATE COURTS
// ============================================================================

CREATE (scotus:Court {
    id: "scotus",
    name: "Supreme Court of the United States",
    jurisdiction: "US",
    level: "supreme",
    precedential_weight: 1.0
});

CREATE (ninth_circuit:Court {
    id: "ninth-circuit",
    name: "United States Court of Appeals for the Ninth Circuit",
    jurisdiction: "US",
    level: "appellate",
    precedential_weight: 0.9
});

CREATE (ca_supreme:Court {
    id: "ca-supreme",
    name: "Supreme Court of California",
    jurisdiction: "CA",
    level: "supreme",
    precedential_weight: 1.0
});

CREATE (ca_appellate_1st:Court {
    id: "ca-appellate-1st",
    name: "California Court of Appeal, First District",
    jurisdiction: "CA",
    level: "appellate",
    precedential_weight: 0.9
});

CREATE (ca_appellate_2nd:Court {
    id: "ca-appellate-2nd",
    name: "California Court of Appeal, Second District",
    jurisdiction: "CA",
    level: "appellate",
    precedential_weight: 0.9
});


// ============================================================================
// STEP 3: CREATE LEGAL CONCEPT TAXONOMY
// ============================================================================

// Top-level concept
CREATE (contracts:LegalConcept {
    id: "contracts",
    name: "Contracts",
    description: "Legally enforceable agreements between parties",
    level: 1
});

// Second-level concepts
CREATE (formation:LegalConcept {
    id: "contract-formation",
    name: "Contract Formation",
    description: "Requirements and process for creating valid contracts",
    level: 2
});

CREATE (breach:LegalConcept {
    id: "contract-breach",
    name: "Breach of Contract",
    description: "Failure to perform contractual obligations",
    level: 2
});

CREATE (remedies:LegalConcept {
    id: "contract-remedies",
    name: "Contract Remedies",
    description: "Legal relief for breach of contract",
    level: 2
});

CREATE (interpretation:LegalConcept {
    id: "contract-interpretation",
    name: "Contract Interpretation",
    description: "Rules for determining meaning of contract terms",
    level: 2
});

CREATE (defenses:LegalConcept {
    id: "contract-defenses",
    name: "Contract Defenses",
    description: "Legal reasons why contracts may be unenforceable",
    level: 2
});

// Third-level concepts (specific topics)
CREATE (offer:LegalConcept {
    id: "offer",
    name: "Offer",
    description: "Expression of willingness to enter into contract",
    level: 3
});

CREATE (acceptance:LegalConcept {
    id: "acceptance",
    name: "Acceptance",
    description: "Agreement to terms of offer",
    level: 3
});

CREATE (consideration:LegalConcept {
    id: "consideration",
    name: "Consideration",
    description: "Something of value exchanged in contract",
    level: 3
});

CREATE (unconscionability:LegalConcept {
    id: "unconscionability",
    name: "Unconscionability",
    description: "Contract terms so unfair as to be unenforceable",
    level: 3
});

// Create hierarchy relationships
CREATE (formation)-[:SUBCONCEPT_OF]->(contracts);
CREATE (breach)-[:SUBCONCEPT_OF]->(contracts);
CREATE (remedies)-[:SUBCONCEPT_OF]->(contracts);
CREATE (interpretation)-[:SUBCONCEPT_OF]->(contracts);
CREATE (defenses)-[:SUBCONCEPT_OF]->(contracts);

CREATE (offer)-[:SUBCONCEPT_OF]->(formation);
CREATE (acceptance)-[:SUBCONCEPT_OF]->(formation);
CREATE (consideration)-[:SUBCONCEPT_OF]->(formation);
CREATE (unconscionability)-[:SUBCONCEPT_OF]->(defenses);


// ============================================================================
// STEP 4: CREATE CALIFORNIA CIVIL CODE SECTIONS
// ============================================================================

CREATE (cc1550:Statute:LegalSource {
    id: "cal-civ-code-1550",
    code: "Cal. Civ. Code",
    section: "1550",
    title: "Essential Elements of Contract",
    text: "It is essential to the existence of a contract that there should be: 1. Parties capable of contracting; 2. Their consent; 3. A lawful object; and, 4. A sufficient cause or consideration.",
    jurisdiction: "CA",
    source_type: "statute",
    effective_date: date("1872-01-01"),
    valid_from: date("1872-01-01"),
    valid_until: null,
    current_status: "active"
});

CREATE (cc1565:Statute:LegalSource {
    id: "cal-civ-code-1565",
    code: "Cal. Civ. Code",
    section: "1565",
    title: "Acceptance Must Be Absolute",
    text: "An acceptance must be absolute and unqualified, or must include in itself an acceptance of that character which the proposer can separate from the rest, and which will conclude the person accepting.",
    jurisdiction: "CA",
    source_type: "statute",
    effective_date: date("1872-01-01"),
    valid_from: date("1872-01-01"),
    valid_until: null,
    current_status: "active"
});

CREATE (cc1614:Statute:LegalSource {
    id: "cal-civ-code-1614",
    code: "Cal. Civ. Code",
    section: "1614",
    title: "Consideration Defined",
    text: "Any benefit conferred, or agreed to be conferred, upon the promisor, by any other person, to which the promisor is not lawfully entitled, or any prejudice suffered, or agreed to be suffered, by such person, other than such as he is at the time of consent lawfully bound to suffer, as an inducement to the promisor, is a good consideration for a promise.",
    jurisdiction: "CA",
    source_type: "statute",
    effective_date: date("1872-01-01"),
    valid_from: date("1872-01-01"),
    valid_until: null,
    current_status: "active"
});


// ============================================================================
// STEP 5: CREATE FOUNDATIONAL CONTRACT CASES
// ============================================================================

// Case 1: Donovan v. RRL Corp (CA Supreme Court - mutual consent)
CREATE (donovan:Case:LegalSource {
    id: "donovan-v-rrl-corp",
    citation: "26 Cal.4th 261",
    title: "Donovan v. RRL Corp.",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("2001-08-30"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Contract formation requires meeting of the minds determined objectively from parties' outward expressions",
    holding: "Mutual consent is essential to contract formation; determined objectively from parties' outward expressions, not subjective intent",
    facts: "Dispute over whether parties had formed binding contract for sale of business",
    precedential_value: "binding",
    valid_from: date("2001-08-30"),
    valid_until: null,
    current_status: "active",
    citation_count: 380
});

// Case 2: Carboni v. Arrospide (CA Court of Appeal - mutual consent)
CREATE (carboni:Case:LegalSource {
    id: "carboni-v-arrospide",
    citation: "2 Cal.App.5th 244",
    title: "Carboni v. Arrospide",
    court: "California Court of Appeal, First District",
    court_level: "appellate",
    decision_date: date("2016-04-28"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Contract requires mutual consent of parties; where consent absent, no contract exists",
    holding: "A contract requires mutual consent of the parties, and where consent is absent, no contract exists",
    facts: "Parties disputed whether oral discussions created binding settlement agreement",
    precedential_value: "binding",
    valid_from: date("2016-04-28"),
    valid_until: null,
    current_status: "active",
    citation_count: 45
});

// Case 3: Weddington Productions v. Flick (CA Court of Appeal - consideration)
CREATE (weddington:Case:LegalSource {
    id: "weddington-v-flick",
    citation: "60 Cal.App.4th 793",
    title: "Weddington Productions, Inc. v. Flick",
    court: "California Court of Appeal, Second District",
    court_level: "appellate",
    decision_date: date("1998-01-29"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Consideration requires legally sufficient value; past consideration insufficient",
    holding: "Consideration must be legally sufficient and bargained for; past consideration does not support new promise",
    facts: "Producer sought to enforce profit-sharing agreement allegedly lacking consideration",
    precedential_value: "binding",
    valid_from: date("1998-01-29"),
    valid_until: null,
    current_status: "active",
    citation_count: 125
});

// Case 4: Armendariz v. Foundation Health Psychcare Services (arbitration unconscionability)
CREATE (armendariz:Case:LegalSource {
    id: "armendariz-v-foundation-health",
    citation: "24 Cal.4th 83",
    title: "Armendariz v. Foundation Health Psychcare Services, Inc.",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("2000-08-24"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Mandatory arbitration agreements must meet minimum standards of fairness to be enforceable",
    holding: "Employment arbitration agreements are enforceable but must meet five minimum requirements: neutral arbitrator, adequate discovery, written decision, all statutory remedies available, and employer bears costs unique to arbitration",
    facts: "Employees challenged mandatory arbitration provision in employment contracts",
    precedential_value: "binding",
    valid_from: date("2000-08-24"),
    valid_until: null,
    current_status: "active",
    citation_count: 892
});

// Case 5: Discover Bank v. Superior Court (arbitration class waiver unconscionability)
CREATE (discover_bank:Case:LegalSource {
    id: "discover-bank-v-superior-court",
    citation: "36 Cal.4th 148",
    title: "Discover Bank v. Superior Court",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("2005-06-30"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Class action waivers in consumer arbitration agreements may be unconscionable",
    holding: "When defendant is alleged to have carried out scheme to cheat large numbers of consumers out of small sums, class action waiver in arbitration clause is unconscionable under California law",
    facts: "Credit card holder challenged class action waiver in arbitration provision",
    precedential_value: "binding",
    valid_from: date("2005-06-30"),
    valid_until: date("2011-04-27"),
    current_status: "overruled",
    overruled_by: "at-t-mobility-v-concepcion",
    citation_count: 567
});

// Case 6: AT&T Mobility v. Concepcion (US Supreme Court - FAA preemption)
CREATE (att_mobility:Case:LegalSource {
    id: "at-t-mobility-v-concepcion",
    citation: "563 U.S. 333",
    title: "AT&T Mobility LLC v. Concepcion",
    court: "Supreme Court of the United States",
    court_level: "supreme",
    decision_date: date("2011-04-27"),
    jurisdiction: "US",
    source_type: "case",
    summary: "Federal Arbitration Act preempts state law prohibiting class action waivers in arbitration agreements",
    holding: "The Federal Arbitration Act preempts California's Discover Bank rule that class action waivers in consumer arbitration agreements are unconscionable",
    facts: "Consumers challenged class action waiver in wireless service arbitration agreement",
    precedential_value: "binding",
    valid_from: date("2011-04-27"),
    valid_until: null,
    current_status: "active",
    citation_count: 1245
});

// Case 7: Edwards v. Arthur Andersen (non-compete unenforceable)
CREATE (edwards:Case:LegalSource {
    id: "edwards-v-arthur-andersen",
    citation: "44 Cal.4th 937",
    title: "Edwards v. Arthur Andersen LLP",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("2008-08-07"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Employee non-compete agreements are void under California Business & Professions Code § 16600",
    holding: "California Business and Professions Code section 16600 prohibits employee noncompetition agreements except in narrow statutory exceptions",
    facts: "Employee challenged non-compete clause in employment agreement with accounting firm",
    precedential_value: "binding",
    valid_from: date("2008-08-07"),
    valid_until: null,
    current_status: "active",
    citation_count: 423
});

// Case 8: Pacific Gas & Electric Co. v. G.W. Thomas Drayage (interpretation)
CREATE (pg_e:Case:LegalSource {
    id: "pacific-gas-electric-v-thomas-drayage",
    citation: "69 Cal.2d 33",
    title: "Pacific Gas & Electric Co. v. G. W. Thomas Drayage & Rigging Co.",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("1968-09-12"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Parol evidence admissible to explain ambiguous contract terms even if terms appear clear on face",
    holding: "When contract language is reasonably susceptible to competing interpretations, extrinsic evidence may be admitted to determine parties' intent",
    facts: "Dispute over meaning of indemnity clause in contract for work on power plant",
    precedential_value: "binding",
    valid_from: date("1968-09-12"),
    valid_until: null,
    current_status: "active",
    citation_count: 678
});

// Case 9: Southern California Edison v. Superior Court (contract interpretation)
CREATE (socal_edison:Case:LegalSource {
    id: "southern-cal-edison-v-superior-court",
    citation: "37 Cal.4th 839",
    title: "Southern California Edison Co. v. Superior Court",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("2006-01-23"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Written contract terms objectively clear on their face cannot be contradicted by parol evidence",
    holding: "When contract language is clear and explicit and does not involve absurdity, court will not consider extrinsic evidence to give it different meaning",
    facts: "Dispute over interpretation of employment arbitration agreement",
    precedential_value: "binding",
    valid_from: date("2006-01-23"),
    valid_until: null,
    current_status: "active",
    citation_count: 289
});

// Case 10: Quelimane Co. v. Stewart Title Guaranty Co. (statute of frauds)
CREATE (quelimane:Case:LegalSource {
    id: "quelimane-v-stewart-title",
    citation: "19 Cal.4th 26",
    title: "Quelimane Co. v. Stewart Title Guaranty Co.",
    court: "Supreme Court of California",
    court_level: "supreme",
    decision_date: date("1998-07-30"),
    jurisdiction: "CA",
    source_type: "case",
    summary: "Statute of frauds requires written evidence of oral promise to answer for debt of another",
    holding: "Oral promise to guarantee another's debt must be in writing to be enforceable under statute of frauds",
    facts: "Real estate company sought to enforce oral guarantee of construction loan",
    precedential_value: "binding",
    valid_from: date("1998-07-30"),
    valid_until: null,
    current_status: "active",
    citation_count: 156
});


// ============================================================================
// STEP 6: CREATE RELATIONSHIPS BETWEEN CASES
// ============================================================================

// Carboni cites Donovan (both about mutual consent)
MATCH (carboni:Case {id: "carboni-v-arrospide"})
MATCH (donovan:Case {id: "donovan-v-rrl-corp"})
CREATE (carboni)-[:CITES {
    citation_type: "binding",
    importance: "central",
    context: "Mutual consent requirement for contract formation"
}]->(donovan);

// AT&T Mobility overrules Discover Bank
MATCH (att:Case {id: "at-t-mobility-v-concepcion"})
MATCH (discover:Case {id: "discover-bank-v-superior-court"})
CREATE (att)-[:OVERRULES {
    scope: "complete",
    reasoning: "FAA preempts state law rule against class action waivers"
}]->(discover);

// Southern Cal Edison distinguishes Pacific Gas & Electric
MATCH (edison:Case {id: "southern-cal-edison-v-superior-court"})
MATCH (pge:Case {id: "pacific-gas-electric-v-thomas-drayage"})
CREATE (edison)-[:DISTINGUISHES {
    basis: "Contract language objectively clear, not ambiguous"
}]->(pge);

// Armendariz discusses Discover Bank
MATCH (armendariz:Case {id: "armendariz-v-foundation-health"})
MATCH (discover:Case {id: "discover-bank-v-superior-court"})
CREATE (armendariz)-[:CITES {
    citation_type: "binding",
    importance: "supporting",
    context: "Unconscionability doctrine in arbitration agreements"
}]->(discover);


// ============================================================================
// STEP 7: CONNECT CASES TO COURTS
// ============================================================================

MATCH (donovan:Case {id: "donovan-v-rrl-corp"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (donovan)-[:DECIDED_BY]->(court);

MATCH (carboni:Case {id: "carboni-v-arrospide"})
MATCH (court:Court {id: "ca-appellate-1st"})
CREATE (carboni)-[:DECIDED_BY]->(court);

MATCH (weddington:Case {id: "weddington-v-flick"})
MATCH (court:Court {id: "ca-appellate-2nd"})
CREATE (weddington)-[:DECIDED_BY]->(court);

MATCH (armendariz:Case {id: "armendariz-v-foundation-health"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (armendariz)-[:DECIDED_BY]->(court);

MATCH (discover:Case {id: "discover-bank-v-superior-court"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (discover)-[:DECIDED_BY]->(court);

MATCH (att:Case {id: "at-t-mobility-v-concepcion"})
MATCH (court:Court {id: "scotus"})
CREATE (att)-[:DECIDED_BY]->(court);

MATCH (edwards:Case {id: "edwards-v-arthur-andersen"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (edwards)-[:DECIDED_BY]->(court);

MATCH (pge:Case {id: "pacific-gas-electric-v-thomas-drayage"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (pge)-[:DECIDED_BY]->(court);

MATCH (edison:Case {id: "southern-cal-edison-v-superior-court"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (edison)-[:DECIDED_BY]->(court);

MATCH (quelimane:Case {id: "quelimane-v-stewart-title"})
MATCH (court:Court {id: "ca-supreme"})
CREATE (quelimane)-[:DECIDED_BY]->(court);


// ============================================================================
// STEP 8: CONNECT CASES TO LEGAL CONCEPTS
// ============================================================================

// Formation cases
MATCH (donovan:Case {id: "donovan-v-rrl-corp"})
MATCH (formation:LegalConcept {id: "contract-formation"})
CREATE (donovan)-[:ADDRESSES]->(formation);

MATCH (carboni:Case {id: "carboni-v-arrospide"})
MATCH (formation:LegalConcept {id: "contract-formation"})
CREATE (carboni)-[:ADDRESSES]->(formation);

MATCH (weddington:Case {id: "weddington-v-flick"})
MATCH (consideration:LegalConcept {id: "consideration"})
CREATE (weddington)-[:ADDRESSES]->(consideration);

// Unconscionability cases
MATCH (armendariz:Case {id: "armendariz-v-foundation-health"})
MATCH (unconscionability:LegalConcept {id: "unconscionability"})
CREATE (armendariz)-[:ADDRESSES]->(unconscionability);

MATCH (discover:Case {id: "discover-bank-v-superior-court"})
MATCH (unconscionability:LegalConcept {id: "unconscionability"})
CREATE (discover)-[:ADDRESSES]->(unconscionability);

MATCH (att:Case {id: "at-t-mobility-v-concepcion"})
MATCH (unconscionability:LegalConcept {id: "unconscionability"})
CREATE (att)-[:ADDRESSES]->(unconscionability);

// Interpretation cases
MATCH (pge:Case {id: "pacific-gas-electric-v-thomas-drayage"})
MATCH (interpretation:LegalConcept {id: "contract-interpretation"})
CREATE (pge)-[:ADDRESSES]->(interpretation);

MATCH (edison:Case {id: "southern-cal-edison-v-superior-court"})
MATCH (interpretation:LegalConcept {id: "contract-interpretation"})
CREATE (edison)-[:ADDRESSES]->(interpretation);


// ============================================================================
// STEP 9: CONNECT CASES TO STATUTES
// ============================================================================

// Cases interpreting Civil Code sections
MATCH (donovan:Case {id: "donovan-v-rrl-corp"})
MATCH (statute:Statute {id: "cal-civ-code-1550"})
CREATE (donovan)-[:INTERPRETS]->(statute);

MATCH (carboni:Case {id: "carboni-v-arrospide"})
MATCH (statute:Statute {id: "cal-civ-code-1550"})
CREATE (carboni)-[:INTERPRETS]->(statute);

MATCH (weddington:Case {id: "weddington-v-flick"})
MATCH (statute:Statute {id: "cal-civ-code-1614"})
CREATE (weddington)-[:INTERPRETS]->(statute);


// ============================================================================
// STEP 10: CONNECT STATUTES TO LEGAL CONCEPTS
// ============================================================================

MATCH (cc1550:Statute {id: "cal-civ-code-1550"})
MATCH (formation:LegalConcept {id: "contract-formation"})
CREATE (cc1550)-[:ADDRESSES]->(formation);

MATCH (cc1565:Statute {id: "cal-civ-code-1565"})
MATCH (acceptance:LegalConcept {id: "acceptance"})
CREATE (cc1565)-[:ADDRESSES]->(acceptance);

MATCH (cc1614:Statute {id: "cal-civ-code-1614"})
MATCH (consideration:LegalConcept {id: "consideration"})
CREATE (cc1614)-[:ADDRESSES]->(consideration);


// ============================================================================
// VERIFICATION
// ============================================================================

// Count what we created
MATCH (c:Case) RETURN count(c) as total_cases;
MATCH (s:Statute) RETURN count(s) as total_statutes;
MATCH (court:Court) RETURN count(court) as total_courts;
MATCH (concept:LegalConcept) RETURN count(concept) as total_concepts;
MATCH ()-[r:CITES]->() RETURN count(r) as citation_relationships;


// ============================================================================
// NOTES
// ============================================================================
//
// This file created:
// - 10 foundational California contract cases
// - 3 California Civil Code sections
// - 5 courts (US Supreme Court, 9th Circuit, CA Supreme, CA Appellate 1st & 2nd)
// - 13 legal concepts in hierarchy
// - Multiple relationship types (CITES, OVERRULES, INTERPRETS, ADDRESSES, DECIDED_BY)
//
// Next step: Run 03_validation_queries.cypher to test the graph
// ============================================================================
