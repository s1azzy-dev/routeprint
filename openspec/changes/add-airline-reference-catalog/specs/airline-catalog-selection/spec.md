## ADDED Requirements

### Requirement: Authenticated users can search approved and pending airlines

The system SHALL provide a bounded authenticated airline search over canonical
names and all public designators. Results SHALL include approved and pending
records, rank approved records first, and exclude rejected, merged, and system
placeholder records from ordinary matching.

#### Scenario: Search by airline name

- **GIVEN** an authenticated user
- **WHEN** the user searches by a normalized airline name
- **THEN** a bounded set of matching approved and pending airlines is returned

#### Scenario: Search a shared public code

- **GIVEN** multiple airlines have the same public designator
- **WHEN** an authenticated user searches that code
- **THEN** every matching selectable airline is returned as a separate
  candidate
- **AND THEN** the system does not select one candidate automatically

#### Scenario: Guest searches the catalog

- **WHEN** a visitor without an authenticated session requests airline lookup
- **THEN** the request is redirected to sign in or otherwise denied
- **AND THEN** no catalog data is returned

### Requirement: User-facing results use one understandable preferred code

The system SHALL display an airline name and at most one preferred public code
without IATA or ICAO terminology in ordinary selection results. Country,
inactive state, and pending state SHALL provide disambiguation when applicable.

#### Scenario: Display the commercial code

- **GIVEN** an airline has both current IATA and ICAO designators
- **WHEN** it appears in ordinary selection
- **THEN** the result displays its name and IATA designator as the preferred
  code
- **AND THEN** it does not display the standard names

#### Scenario: Fall back to another available code

- **GIVEN** an airline has no applicable IATA designator but has an ICAO
  designator
- **WHEN** it appears in ordinary selection
- **THEN** that ICAO designator is displayed as the single preferred code

#### Scenario: Mark an unverified candidate

- **WHEN** a pending airline appears in selection results
- **THEN** it is clearly labelled as unverified
- **AND THEN** the user can still select it

### Requirement: Authenticated users can submit a missing global airline

The system SHALL let an authenticated user explicitly create a global pending
airline with a required name and optional generic code and country. The system
SHALL infer the supplied code system from supported format, retain submission
audit, and SHALL NOT make the airline user-owned.

#### Scenario: Submit a name-only candidate

- **GIVEN** an authenticated user has confirmed no existing result is suitable
- **WHEN** the user submits a valid airline name without code or country
- **THEN** one global pending airline is created
- **AND THEN** the original submission and submitter are retained for admin
  audit

#### Scenario: Submit a supported code

- **WHEN** a user submits a two-character alphanumeric or three-letter airline
  code
- **THEN** the code is normalized and stored under its inferred designator
  system

#### Scenario: Reject malformed candidate input

- **WHEN** a user submits a blank name, unsupported code format, or oversized
  text
- **THEN** no airline is created
- **AND THEN** actionable validation errors are returned

### Requirement: Exact pending submissions are reused

The system SHALL search existing approved and pending records before creating a
candidate. An exact normalized pending match SHALL be reused, while a shared
code alone SHALL NOT prevent a separately confirmed candidate.

#### Scenario: Reuse an existing pending candidate

- **GIVEN** an exact matching pending airline already exists
- **WHEN** another authenticated user attempts the same submission
- **THEN** the existing pending airline is returned for selection
- **AND THEN** no duplicate pending airline is created

#### Scenario: Confirm a distinct airline with a shared code

- **GIVEN** existing airlines share the submitted code but differ from the
  proposed name or country evidence
- **WHEN** the user explicitly confirms the proposal represents another airline
- **THEN** a distinct pending airline can be created

### Requirement: Selection payloads exclude protected evidence

The system SHALL return only allowlisted airline display and selection fields
to ordinary users. Submission audit, reviewer identity, review notes, raw
Wikidata data, source payloads, and internal diagnostics SHALL NOT appear in
ordinary responses or Inertia props.

#### Scenario: Render airline choices

- **WHEN** an authenticated flight-facing page receives airline choices
- **THEN** each choice contains only its Routeprint selection identifier,
  display name, preferred code, country display value when available, and
  exceptional state labels
