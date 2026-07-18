## ADDED Requirements

### Requirement: Country boundaries are delivered as a static code-keyed asset
The system SHALL maintain an application-owned, versioned country-boundary
asset derived from an approved Natural Earth release. Every displayable feature
SHALL expose `countryCode`; client code SHALL NOT join boundaries to countries
by display name or an implicit numeric identifier.

#### Scenario: Match a visited country to a boundary
- **WHEN** a future map surface receives a visited country code
- **THEN** it can select the matching boundary feature by `countryCode`

### Requirement: Boundary generation verifies territory coverage
The boundary-generation workflow SHALL verify that every catalog country has
exactly one displayable country-code mapping before accepting a generated
asset. An unmapped or ambiguous territory SHALL fail generation with a
diagnostic.

#### Scenario: Detect a missing territory boundary
- **WHEN** a catalog country has no matching Natural Earth feature or explicit
  mapping
- **THEN** the workflow fails instead of shipping a partially mappable layer
