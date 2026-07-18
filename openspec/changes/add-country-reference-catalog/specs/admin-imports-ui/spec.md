## ADDED Requirements

### Requirement: Admin navigation exposes country imports
The system SHALL expose a `Countries` link beside `Airports` in the protected
Imports navigation, leading to the country-catalog import history page.

#### Scenario: Administrator sees country imports navigation
- **GIVEN** an authenticated administrator opens an admin page
- **WHEN** the page renders the Imports navigation
- **THEN** it includes a `Countries` link to the country imports page

#### Scenario: Country imports navigation is active
- **GIVEN** an authenticated administrator opens the country imports page
- **WHEN** the page renders
- **THEN** the Imports/Countries navigation item is marked current

### Requirement: Administrators can inspect bounded country import history
The system SHALL render a newest-first paginated table of persisted
`country_catalog` runs. Rows SHALL expose only the
same safe operator-facing run fields as airport imports: source, mode,
allowlisted effective parameters, status, progress counters, and timestamps.

#### Scenario: Render country import history
- **GIVEN** an authenticated administrator and persisted country-source runs
- **WHEN** the administrator requests the country imports page
- **THEN** the response renders the `Admin/Imports/Countries/Index` page with
  only those source runs and safe row props

#### Scenario: Paginate country import history
- **GIVEN** more country-source runs exist than one page contains
- **WHEN** the administrator requests a later page
- **THEN** the response returns only that bounded page and its pagination props

### Requirement: Only administrators can access country import operations
The system SHALL require an authenticated administrator for country import
history and start actions.

#### Scenario: Member cannot inspect country imports
- **GIVEN** an authenticated non-admin member
- **WHEN** the member requests the country imports page
- **THEN** the request is redirected to the public home page

#### Scenario: Guest cannot start a country refresh
- **GIVEN** a visitor without an authenticated session
- **WHEN** the visitor submits the country import start action
- **THEN** the request is redirected to sign in and no import run is created

### Requirement: Administrator can start a complete country refresh
The system SHALL provide a country-import start button that starts one full
`country_catalog` run through the composite processor, using server-defined
artifact parameters and the current administrator as initiator.

#### Scenario: Start a country refresh
- **GIVEN** an authenticated administrator and an enabled country catalog source
- **WHEN** the administrator submits the country import start action
- **THEN** one queued full catalog run is created with the administrator as
  initiator and the response redirects to country imports with a success notice

#### Scenario: Reject a start with an active country source
- **GIVEN** an authenticated administrator and an active country catalog run
- **WHEN** the administrator submits the country import start action
- **THEN** no new run is created and the response redirects with an alert

#### Scenario: Reject a start with an unavailable country source
- **GIVEN** an authenticated administrator and a missing or disabled country
  catalog source
- **WHEN** the administrator submits the country import start action
- **THEN** no partial run is created and the response redirects with an alert
