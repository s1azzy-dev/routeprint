## ADDED Requirements

### Requirement: Country catalog persists airport territories
The system SHALL persist a canonical country or territory for every accepted
OurAirports country code. A country SHALL have a Routeprint identity, a unique
uppercase two-letter code, a non-empty canonical fallback name, and a continent
code. The catalog SHALL accept `XK` when it is supplied by the approved
membership source.

#### Scenario: Persist an airport territory
- **WHEN** the approved membership source contains `XK` with a canonical name
  and continent code
- **THEN** the system persists one country with code `XK`

#### Scenario: Reject duplicate country code
- **WHEN** a second country is created with an existing country code
- **THEN** validation and the database uniqueness boundary reject it

### Requirement: Countries support localized display names
The system SHALL persist at most one localized country name for each enabled
locale and SHALL provide the canonical country name as a fallback when a
localized name is unavailable.

#### Scenario: Persist English and Russian names
- **WHEN** the catalog applies CLDR names for `en` and `ru` to a country
- **THEN** both localized names are persisted for that country

#### Scenario: Use canonical fallback
- **WHEN** a caller requests a locale without a country-name record
- **THEN** the country canonical name is returned

#### Scenario: Reject duplicate localized name
- **WHEN** a second localized name is added for the same country and locale
- **THEN** validation and the database uniqueness boundary reject it
