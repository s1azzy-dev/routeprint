## ADDED Requirements

### Requirement: Wikidata rows map through stable source identity

The system SHALL identify an imported Wikidata airline by QID and persist an
explicit source link to the Routeprint airline. Names and public designators
SHALL remain lookup evidence and SHALL NOT be source identity or automatic
merge keys.

#### Scenario: Import a new unambiguous airline

- **GIVEN** a structurally valid Wikidata airline row with a new QID and no
  ambiguous catalog candidates
- **WHEN** the row is applied
- **THEN** one approved Routeprint airline and its valid designators are
  persisted
- **AND THEN** a source link records the QID and match strategy

#### Scenario: Preserve a code collision boundary

- **GIVEN** an unlinked Wikidata row shares a public designator with an existing
  airline
- **WHEN** the source evidence cannot identify one safe target
- **THEN** the raw source record and diagnostic are retained
- **AND THEN** the importer does not merge or overwrite an airline solely
  because of that code

### Requirement: Trusted valid records publish without individual moderation

The system SHALL automatically approve a new Wikidata-backed airline that
passes source eligibility, structural validation, and ambiguity checks.
User-submitted airlines SHALL continue to require moderation.

#### Scenario: Publish a trusted imported record

- **WHEN** a new Wikidata-backed airline passes all import checks
- **THEN** it becomes selectable as an approved catalog record
- **AND THEN** it has no human approver attributed

#### Scenario: Quarantine an invalid imported record

- **WHEN** an imported row has invalid required identity or malformed supplied
  designator data
- **THEN** the item fails with sanitized diagnostics after raw persistence
- **AND THEN** no approved airline is created from that row

### Requirement: Wikidata reimports are idempotent

The system SHALL use QID, persisted checksums, source snapshots, and explicit
links to prevent duplicate airlines and designators under at-least-once
delivery.

#### Scenario: Reimport unchanged content

- **GIVEN** a QID is already linked and its normalized content is unchanged
- **WHEN** the item is delivered again
- **THEN** the existing source record, airline, designators, and link are reused
- **AND THEN** no duplicate catalog data is created

#### Scenario: Reimport changed linked content

- **GIVEN** a QID is linked and its source-managed content changes
- **WHEN** the changed row passes validation
- **THEN** a source snapshot records the change
- **AND THEN** only source-governed fields of the linked airline are updated

### Requirement: Import preserves optional and historical evidence

The system SHALL accept a valid airline with missing country or date evidence,
persist available operational and designator validity data, and include closed
airlines in the catalog.

#### Scenario: Import a closed historical airline

- **WHEN** Wikidata identifies an eligible airline as no longer operating
- **THEN** the importer persists it as an approved inactive airline
- **AND THEN** it remains available for historical selection

#### Scenario: Import an unmatched country reference

- **WHEN** an otherwise valid row supplies country evidence that cannot be
  resolved through the country catalog
- **THEN** the airline remains persistable without an invented country
- **AND THEN** the unmatched evidence is retained in import diagnostics

### Requirement: Full snapshot reconciliation does not delete airlines

The system SHALL mark a linked Wikidata source record missing upstream when it
is absent from a completed authoritative snapshot and SHALL retain its
canonical airline and historical references.

#### Scenario: Reconcile a missing QID

- **GIVEN** a linked QID is absent from a completed full snapshot
- **WHEN** reconciliation finishes
- **THEN** the source record is marked missing upstream with run provenance
- **AND THEN** the airline and its designator history remain persisted

### Requirement: Airline import follows protected retryable orchestration

The system SHALL execute the Wikidata airline import through the existing
reference-import run and item lifecycle with one active run per source,
private raw artifacts, durable counters, and sanitized failure diagnostics.

#### Scenario: Retry after a failed run

- **GIVEN** a completed failed airline import run
- **WHEN** an administrator starts a new full run after correcting the cause
- **THEN** the failed history remains immutable
- **AND THEN** the successor run can safely reprocess QID-backed records without
  duplicating canonical data
