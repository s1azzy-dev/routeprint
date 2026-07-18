## ADDED Requirements

### Requirement: Country catalog import preserves provider artifact provenance
The system SHALL use one `country_catalog` source and one import run to capture
OurAirports country membership plus independent Unicode CLDR territory artifacts
for `en` and `ru`. Each artifact SHALL retain provider, dataset, URL,
versioned configuration, checksum, and sanitized diagnostics under the existing
import boundary.

#### Scenario: Stage approved source snapshots
- **WHEN** an administrator starts a country-catalog refresh
- **THEN** the system stages one catalog run and work item containing distinct
  OurAirports, CLDR English, and CLDR Russian artifacts without treating either
  provider as the canonical country identity

### Requirement: Catalog refresh applies only a complete validated package
The system SHALL upsert countries and localized names only after the composite
processor validates all package artifacts. The domain apply operation SHALL be
transactional and idempotent.

#### Scenario: Apply a complete package
- **WHEN** a country code appears in the OurAirports membership snapshot and
  both required CLDR locales supply valid names
- **THEN** one canonical country and its two localized names are created or
  updated without duplicates

#### Scenario: Reject an incomplete package
- **WHEN** a required CLDR name is missing or any package artifact is invalid
- **THEN** the refresh records a diagnostic and leaves the existing canonical
  country catalog unchanged

#### Scenario: Retry a previously applied refresh
- **WHEN** the composite processor retries unchanged successful package artifacts
- **THEN** it does not duplicate countries, names, source records, or links
