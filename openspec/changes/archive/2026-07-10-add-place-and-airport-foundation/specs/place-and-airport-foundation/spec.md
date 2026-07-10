## ADDED Requirements

### Requirement: Canonical places persist real-world location data

The system SHALL persist a canonical place with a non-empty fallback name,
airport place kind, geographic context, and a WGS84 point location. A place MAY
have unresolved timezone metadata, but any supplied timezone SHALL be a valid
IANA identifier.

#### Scenario: Create an airport place with spatial and timezone data

- **WHEN** a place is created with an airport kind, name, country code, a
  `geography(Point, 4326)` location, and an IANA timezone
- **THEN** the place is persisted with the point, timezone, timezone source, and
  optional verification timestamp

#### Scenario: Reject an invalid timezone

- **WHEN** a place is validated with an unknown timezone identifier
- **THEN** the place is invalid and reports a timezone validation error

#### Scenario: Preserve an unresolved timezone state

- **WHEN** a place is created without a timezone or verification timestamp
- **THEN** the place remains persistable with null timezone metadata and does not
  fabricate a verification time

### Requirement: Places support localized names with fallback

The system SHALL persist at most one localized name for each place and locale.
The canonical place name SHALL remain available as the fallback when a requested
locale has no translation.

#### Scenario: Add English and Russian names

- **WHEN** a place receives valid `en` and `ru` localized names
- **THEN** both names are persisted and associated with the same place

#### Scenario: Reject duplicate locale names

- **WHEN** a second localized name is added for the same place and locale
- **THEN** validation and the database uniqueness constraint reject the duplicate

#### Scenario: Use the canonical fallback

- **WHEN** a requested locale has no matching `place_names` record
- **THEN** the place's canonical `name` is available as the display fallback

### Requirement: Airport records persist aviation-specific data

The system SHALL persist an airport as a one-to-one fixed-wing specialization
of a place. It SHALL support operational status and optional IATA and ICAO
lookup codes.

#### Scenario: Persist an active airport with public codes

- **WHEN** an airport is created for a place with active status and IATA and
  ICAO codes
- **THEN** the airport is persisted and remains addressable through its place

#### Scenario: Reject an invalid airport code

- **WHEN** an airport is validated with an IATA code that is not three uppercase
  letters or an ICAO code that is not four uppercase letters
- **THEN** the airport is invalid and reports the corresponding code error

#### Scenario: Enforce one airport per place

- **WHEN** a second airport is assigned to the same place
- **THEN** the database primary-key/foreign-key boundary rejects the duplicate
  specialization

### Requirement: Airport codes are lookup values

The system SHALL normalize and validate supplied IATA and ICAO codes as lookup
attributes. They SHALL NOT define the Routeprint airport identity or be global
database uniqueness constraints.

#### Scenario: Allow a historical code collision

- **WHEN** two airport reference records persist the same code
- **THEN** both records remain persistable and future import logic is
  responsible for diagnosing an ambiguous active lookup

#### Scenario: Allow missing optional codes

- **WHEN** an airport has no IATA or ICAO code
- **THEN** it remains persistable with those fields null

### Requirement: Closed airport records remain referenceable

The system SHALL retain closed fixed-wing airport records for historical travel.
It SHALL not model heliports, seaplane bases, or balloonports in this MVP
airport catalog.

#### Scenario: Persist a closed historical airport

- **WHEN** an airport is created with closed operational status
- **THEN** the airport remains associated with its place and can be referenced
  by a future historical travel segment

### Requirement: Spatial integrity is index-backed

The system SHALL store place locations as PostGIS `geography(Point, 4326)` and
provide a GiST index for spatial lookup.

#### Scenario: Inspect the generated schema

- **WHEN** the database schema is generated after migration
- **THEN** the place location has the required geography type and SRID and a
  GiST index exists on it
