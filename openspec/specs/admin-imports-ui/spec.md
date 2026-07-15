# admin-imports-ui Specification

## Purpose
Admin-only navigation, history, and guarded start operations for the
OurAirports reference-data import.
## Requirements
### Requirement: Admin navigation exposes airport imports
The system SHALL expose an `Imports` section in the protected admin navigation
with an `Airports` link to the airport import history page.

#### Scenario: Administrator sees the Imports section
- **GIVEN** an authenticated administrator opens an admin page
- **WHEN** the page renders the admin navigation
- **THEN** it includes a section labelled `Imports`
- **AND THEN** that section includes an `Airports` link to the airport imports page

#### Scenario: Airport imports navigation is active
- **GIVEN** an authenticated administrator opens the airport imports page
- **WHEN** the page renders
- **THEN** the Imports/Airports navigation item is marked current

### Requirement: Administrators can inspect bounded airport import history
The system SHALL render a paginated table of persisted `ourairports_airports`
import runs, ordered with the newest run first, including source, mode,
allowlisted effective parameters, status, progress counters, and timestamps.

#### Scenario: Render airport import history
- **GIVEN** an authenticated administrator and persisted airport import runs
- **WHEN** the administrator requests the airport imports page
- **THEN** the response renders the `Admin/Imports/Airports/Index` page
- **AND THEN** the page includes the run rows and pagination props
- **AND THEN** the rows include only the safe operator-facing run fields

#### Scenario: Paginate airport import history
- **GIVEN** more airport import runs exist than one page contains
- **WHEN** the administrator requests a later page
- **THEN** the response returns only that bounded page of runs
- **AND THEN** the pagination props identify the current and adjacent pages

### Requirement: Only administrators can access airport import operations
The system SHALL require an authenticated administrator for airport import
history and start actions.

#### Scenario: Member cannot inspect imports
- **GIVEN** an authenticated non-admin member
- **WHEN** the member requests the airport imports page
- **THEN** the request is redirected to the public home page

#### Scenario: Guest cannot start an import
- **GIVEN** a visitor without an authenticated session
- **WHEN** the visitor submits the airport import start action
- **THEN** the request is redirected to sign in
- **AND THEN** no import run is created

### Requirement: Administrator can start the configured airport import
The system SHALL provide a button that starts one full
`ourairports_airports` import through the existing import orchestration, using
server-defined source parameters and the current administrator as initiator.

#### Scenario: Start an airport import
- **GIVEN** an authenticated administrator and an enabled airport import source
- **WHEN** the administrator submits the start action
- **THEN** one queued full import run is created for that source
- **AND THEN** the run records the administrator as initiator
- **AND THEN** the administrator is redirected to the airport imports page with
  a success notice

#### Scenario: Reject a start while another run is active
- **GIVEN** an authenticated administrator and an active airport import run
- **WHEN** the administrator submits the start action
- **THEN** no second run is created
- **AND THEN** the administrator is redirected to the airport imports page with
  an explanatory alert

#### Scenario: Reject a missing or disabled source
- **GIVEN** an authenticated administrator and no enabled airport import source
- **WHEN** the administrator submits the start action
- **THEN** no import run is created
- **AND THEN** the administrator is redirected to the airport imports page with
  an explanatory alert
