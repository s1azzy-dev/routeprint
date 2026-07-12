## ADDED Requirements

### Requirement: Reference sources preserve stable external identity
The system SHALL persist each upstream record under a source-scoped record kind
and external UID, independently from Routeprint domain identifiers.

#### Scenario: Reobserve the same upstream record
- **GIVEN** a source record exists for a source, record kind, and external UID
- **WHEN** a later run receives that same identity
- **THEN** the system updates the existing staged record rather than creating a
  duplicate identity

#### Scenario: Distinguish records from different sources
- **GIVEN** two sources expose the same external UID and record kind
- **WHEN** both records are imported
- **THEN** the system persists separate source records and provenance histories

### Requirement: Raw input and changed payload history are retained
The system SHALL retain the original source artifact and the raw and normalized
representation of a source record, with a checksum and a snapshot for each
changed payload version.

#### Scenario: Record a new source row
- **WHEN** a source row is first normalized successfully
- **THEN** its raw payload, normalized payload, checksum, first-seen time, and
  source artifact provenance are persisted
- **AND THEN** a snapshot records that initial content under the current run

#### Scenario: Reimport unchanged content
- **GIVEN** a source record has the same normalized and raw content checksum as
  the received row
- **WHEN** the row is processed again
- **THEN** its last-seen information is refreshed without creating a new payload
  snapshot

#### Scenario: Reimport changed content
- **GIVEN** a source record exists with a different checksum
- **WHEN** the changed row is processed
- **THEN** its current payload is updated and a new snapshot is attached to the
  current run

### Requirement: Canonical failures preserve the raw staging boundary
The system SHALL stop the item on the first invalid, incomplete, or ambiguous
source row, retain the committed raw stage, and SHALL not commit canonical or
normalized-record changes from the failed apply phase.

#### Scenario: Stop after an invalid row
- **GIVEN** a run item contains one invalid row and later valid rows
- **WHEN** the item is processed
- **THEN** the raw rows are retained in source records
- **AND THEN** canonical and normalized-record writes from the apply phase are
  rolled back
- **AND THEN** later rows are not processed
- **AND THEN** the item stores a stable failure code and row number

#### Scenario: Preserve explicit failures
- **WHEN** parsing, matching, or applying a source row fails
- **THEN** the item records its stable error code, exception class/message, and
  backtrace
- **AND THEN** the application log records the exception with the run-item ID
- **AND THEN** neither contains the raw payload, signed artifact URL, or
  credentials

### Requirement: Raw import data stays internal
The system SHALL keep source artifacts, raw payloads, and detailed diagnostics
out of public, map, and ordinary application response surfaces.

#### Scenario: Serialize a non-import catalog response
- **GIVEN** an airport has import provenance
- **WHEN** it is returned through an ordinary catalog or map-facing response
- **THEN** the response omits raw artifacts, raw source payloads, detailed
  diagnostics, and internal import identifiers
