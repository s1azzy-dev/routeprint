## ADDED Requirements

### Requirement: Manual flight history is private and user-owned

The system SHALL associate every manual travel segment with its authenticated
owner and SHALL authorize list, read, update, and delete behavior against that
owner. Client input SHALL NOT select or replace ownership.

#### Scenario: Create a flight for the current user

- **WHEN** an authenticated user submits a valid manual flight
- **THEN** the resulting travel segment belongs to that current user
- **AND THEN** any client-supplied owner value is ignored or rejected

#### Scenario: Prevent cross-user access

- **GIVEN** a flight belongs to another user
- **WHEN** an authenticated member attempts to read, update, or delete it
- **THEN** the request is denied without exposing or changing the flight

#### Scenario: Guest accesses flight history

- **WHEN** a visitor without an authenticated session requests manual flight
  history
- **THEN** the visitor is redirected to sign in
- **AND THEN** no travel data is rendered

### Requirement: A manual flight records an airport route

The system SHALL persist a manual flight as a flight-specialized travel segment
with departure and arrival airport references. Airline metadata SHALL NOT
determine whether the route itself exists.

#### Scenario: Persist a manual airport route

- **WHEN** an authenticated user submits a valid departure airport and arrival
  airport with the remaining confirmed flight inputs
- **THEN** one owned flight travel segment is persisted with those airport
  references

#### Scenario: Keep route consumers independent from airline quality

- **GIVEN** a valid flight references a pending, rejected, inactive, or unknown
  airline
- **WHEN** a future route or base flight-count consumer reads that flight
- **THEN** the flight remains eligible based on its route evidence

### Requirement: Every flight references a marketing airline

The system SHALL persist every flight detail with a non-null marketing airline
foreign key. If the user leaves airline selection empty, the use case SHALL
assign the protected `unknown_airline` record.

#### Scenario: Select a known airline

- **WHEN** a user selects an approved or pending airline for a valid manual
  flight
- **THEN** that airline is persisted as the flight's marketing airline

#### Scenario: Leave airline selection empty

- **WHEN** a user submits a valid manual flight without selecting an airline
- **THEN** the use case assigns the protected unknown airline
- **AND THEN** the persisted marketing-airline foreign key remains non-null

#### Scenario: Reject an unavailable new selection

- **WHEN** a user attempts to assign a rejected or merged airline to a new
  flight
- **THEN** the flight is not persisted with that unavailable airline
- **AND THEN** an actionable validation error is returned

### Requirement: A flight may identify its operating airline

The system SHALL allow a flight to reference an optional operating airline
separately from its required marketing airline.

#### Scenario: Record a codeshare operator

- **WHEN** a user selects one airline as marketing carrier and another as
  operating carrier
- **THEN** both associations are persisted with their distinct roles

#### Scenario: Omit an unknown operator

- **WHEN** a user does not know the operating airline
- **THEN** the flight remains valid with no operating-airline association

### Requirement: Flight carrier evidence survives catalog moderation

The system SHALL preserve the historical marketing designator recorded for a
flight independently from the current airline association. Catalog merge or
rejection SHALL NOT delete or invalidate the flight.

#### Scenario: Merge a referenced pending airline

- **GIVEN** a flight references a pending airline and stores an observed
  marketing designator
- **WHEN** a moderator merges that airline into an approved target
- **THEN** the flight is relinked to the approved target
- **AND THEN** its observed marketing designator remains unchanged

#### Scenario: Reject a referenced airline

- **GIVEN** a flight references a pending airline
- **WHEN** a moderator rejects that airline without a merge target
- **THEN** the flight remains persisted and private
- **AND THEN** its airport route remains usable

#### Scenario: Edit a flight with a rejected airline

- **GIVEN** a flight references a rejected airline
- **WHEN** its owner edits and submits the flight
- **THEN** the owner must replace that association with an approved airline, a
  pending airline, or the protected unknown airline

### Requirement: Manual schedule follows the accepted time-zone boundary

The system SHALL preserve airport-local schedule values, the departure and
arrival IANA zones used to interpret them, and resolved absolute-time evidence
according to ADR 0006. Final required-field and unresolved-time behavior MUST be
defined before implementation begins.

#### Scenario: Preserve local and resolved schedule evidence

- **WHEN** a confirmed manual schedule is resolved using its departure and
  arrival airport zones
- **THEN** the persisted segment retains local civil values, zone snapshots,
  resolved instants when safely known, and applied offset evidence

#### Scenario: Encounter unresolved local time

- **WHEN** a local schedule value is ambiguous, nonexistent, or lacks a usable
  zone
- **THEN** the system does not silently invent an instant
- **AND THEN** the final pre-implementation specification determines whether
  the manual submission is blocked or retained with explicit unresolved state
