## ADDED Requirements

### Requirement: Airlines have durable Routeprint identity

The system SHALL persist each airline with a Routeprint identifier, a non-empty
canonical name, an independent review state, and an independent operational
state. Public names and designators SHALL NOT define the Routeprint identity.

#### Scenario: Persist an approved active airline

- **WHEN** a valid airline is created with approved review state and active
  operational state
- **THEN** it is persisted under its Routeprint identifier
- **AND THEN** its name or public designators can change without changing that
  identifier

#### Scenario: Keep review and operation independent

- **WHEN** a closed historical airline is approved for catalog use
- **THEN** it remains approved with inactive operational state
- **AND THEN** it remains a selectable historical airline

### Requirement: Public designators are non-unique historical lookup values

The system SHALL associate normalized IATA and ICAO designators with airlines
as lookup assignments with optional validity dates. It SHALL allow the same
public designator to belong to multiple airlines and SHALL NOT resolve airline
identity solely from that code.

#### Scenario: Persist a shared designator

- **GIVEN** an airline already has a supplied public designator
- **WHEN** another valid airline receives the same designator
- **THEN** both assignments remain persistable
- **AND THEN** lookup by that code returns both candidate airlines

#### Scenario: Reject a duplicate assignment within one airline

- **GIVEN** an airline already has a designator assignment for one system and
  code
- **WHEN** the identical assignment is added to that airline again
- **THEN** structural uniqueness rejects the duplicate assignment

#### Scenario: Persist an airline without public codes

- **WHEN** a valid airline has no known IATA or ICAO designator
- **THEN** it remains persistable and searchable by name

### Requirement: Closed airlines remain available for historical selection

The system SHALL retain inactive airlines and rank code-collision candidates
using the requested flight date and available validity evidence without
preventing explicit manual selection.

#### Scenario: Rank a historical code owner

- **GIVEN** an inactive airline and an active airline reuse the same preferred
  code in different periods
- **WHEN** a user searches that code for a date inside the inactive airline's
  available validity evidence
- **THEN** the inactive historical airline ranks ahead of the incompatible
  current airline

#### Scenario: Select an airline outside inferred validity

- **WHEN** a user explicitly selects a returned airline whose recorded dates do
  not match the flight date
- **THEN** the selection remains allowed
- **AND THEN** the system does not silently replace it with another airline

### Requirement: One protected airline represents an unknown carrier

The system SHALL maintain exactly one approved system airline identified by the
stable key `unknown_airline`. Ordinary catalog, moderation, merge, deletion,
and import actions SHALL NOT mutate or remove it.

#### Scenario: Bootstrap the unknown airline idempotently

- **WHEN** the system-airline bootstrap is executed more than once
- **THEN** exactly one `unknown_airline` record exists

#### Scenario: Reject ordinary mutation of the unknown airline

- **WHEN** an administrator or import attempts to edit, reject, merge, or delete
  the protected unknown airline
- **THEN** the operation fails without changing the system record

### Requirement: Catalog lifecycle preserves rejected and merged history

The system SHALL keep rejected and merged airlines persisted, exclude them from
new selection, and record the approved merge target for a merged airline.

#### Scenario: Exclude a rejected airline from selection

- **WHEN** an airline is rejected by a moderator
- **THEN** it no longer appears in airline selection results
- **AND THEN** its persisted identity remains available to authorized existing
  references

#### Scenario: Resolve a merged airline

- **WHEN** an airline has been merged into an approved target
- **THEN** it no longer appears in new selection results
- **AND THEN** its merge target remains recorded
