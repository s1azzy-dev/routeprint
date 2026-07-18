## MODIFIED Requirements

### Requirement: Canonical places persist real-world location data
The system SHALL persist a canonical place with a non-empty fallback name, an
airport place kind, a canonical country association, geographic context, and a
WGS84 point location. A place MAY have unresolved timezone metadata, but any
supplied timezone SHALL be a valid IANA identifier. An incoming source country
code SHALL be resolved to the canonical country before the place is persisted.

#### Scenario: Create an airport place with spatial and timezone data
- **WHEN** a place is created with an airport kind, a canonical country, name,
  `geography(Point, 4326)` location, and an IANA timezone
- **THEN** the place is persisted with its country association, point, timezone,
  timezone source, and optional verification timestamp

#### Scenario: Reject an invalid timezone
- **WHEN** a place is validated with an unknown timezone identifier
- **THEN** the place is invalid and reports a timezone validation error

#### Scenario: Preserve an unresolved timezone state
- **WHEN** a place is created without a timezone or verification timestamp
- **THEN** the place remains persistable with null timezone metadata and does
  not fabricate a verification time

#### Scenario: Reject an unresolved country code
- **WHEN** an airport source record supplies a country code absent from the
  canonical country catalog
- **THEN** canonical place creation fails with a structured import diagnostic
