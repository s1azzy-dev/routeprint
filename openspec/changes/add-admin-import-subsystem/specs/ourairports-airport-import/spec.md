## ADDED Requirements

### Requirement: OurAirports rows map through a provider-neutral airport link
The system SHALL identify an OurAirports airport row by its stable provider row
ID and persist the relation to a Routeprint airport in an explicit source-link
record. IATA and ICAO codes SHALL remain lookup attributes, not mapping keys.

#### Scenario: Import a new eligible airport
- **GIVEN** an eligible fixed-wing OurAirports row with a stable provider ID and
  valid catalog fields
- **WHEN** the row is applied for the first time
- **THEN** the system creates or conservatively matches a canonical place and
  airport through a domain interactor
- **AND THEN** it persists an airport source link using the provider row ID and
  a recorded match strategy

#### Scenario: Preserve a code collision boundary
- **GIVEN** an existing airport has an IATA or ICAO code that also appears in an
  incoming OurAirports row without an existing source link
- **WHEN** the catalog match is ambiguous
- **THEN** the row is staged with an ambiguity issue
- **AND THEN** the system does not merge or overwrite an airport solely because
  of the shared public code

### Requirement: OurAirports reimports are idempotent
The system SHALL use the persisted provider identity, checksum, and airport
source link to avoid duplicate catalog records when a row is reprocessed.

#### Scenario: Reimport unchanged airport content
- **GIVEN** an OurAirports source record is linked to an airport and has an
  unchanged checksum
- **WHEN** a later run processes the same provider row
- **THEN** it reuses the existing source record and airport link
- **AND THEN** it creates no duplicate place, airport, or link

#### Scenario: Reimport changed airport content
- **GIVEN** an OurAirports source record is linked to an airport and receives a
  changed checksum
- **WHEN** the row passes eligibility and validation
- **THEN** the source record obtains a changed-payload snapshot
- **AND THEN** the explicit catalog apply path updates only the linked canonical
  record fields governed by the source policy

### Requirement: Only eligible and valid airport rows reach the catalog
The system SHALL reject facilities outside Routeprint's fixed-wing airport
catalog scope and rows with invalid required catalog data without creating a
canonical airport.

#### Scenario: Reject a facility outside the catalog scope
- **GIVEN** an OurAirports row represents a heliport, seaplane base, balloonport,
  or another excluded facility
- **WHEN** the row is processed
- **THEN** it receives a source-record diagnostic
- **AND THEN** no place, airport, or airport source link is created

#### Scenario: Reject invalid spatial or timezone data
- **GIVEN** an otherwise eligible OurAirports row has invalid coordinates or an
  invalid supplied IANA timezone
- **WHEN** the row is processed
- **THEN** it receives a validation issue and remains unapplied
- **AND THEN** no invalid PostGIS point or airport record is persisted

### Requirement: Airport import preserves the canonical spatial boundary
The system SHALL persist accepted coordinates as the existing WGS84
`geography(Point, 4326)` place location through the domain apply path.

#### Scenario: Apply valid airport coordinates
- **GIVEN** an eligible row has valid longitude and latitude
- **WHEN** its airport is created or updated
- **THEN** its place location uses longitude first and latitude second in WGS84
- **AND THEN** the generated schema and real database preserve the existing
  spatial type and index boundary

### Requirement: Full-source reconciliation does not erase history
The system SHALL record an OurAirports record that disappears from an
authoritative full snapshot as missing upstream without deleting the linked
canonical airport.

#### Scenario: Reconcile a removed provider row
- **GIVEN** a linked airport source record is absent from a completed full
  OurAirports snapshot
- **WHEN** reconciliation runs for that source scope
- **THEN** the source record is marked missing upstream with provenance of the
  completing run
- **AND THEN** its canonical place, airport, and historical references remain
  persisted
