## ADDED Requirements

### Requirement: Admin navigation exposes airline imports

The system SHALL add an `Airlines` link under the protected admin `Imports`
section and mark it current on the airline import page.

#### Scenario: Administrator sees airline imports navigation

- **WHEN** an authenticated administrator opens an admin page
- **THEN** the Imports section includes an Airlines link

#### Scenario: Airline imports navigation is active

- **WHEN** an authenticated administrator opens the airline imports page
- **THEN** the Imports/Airlines navigation item is marked current

### Requirement: Administrators can inspect bounded airline import history

The system SHALL render a newest-first paginated table of persisted
`wikidata_airlines` runs with source, mode, allowlisted effective parameters,
status, progress counters, and timestamps.

#### Scenario: Render airline import history

- **GIVEN** persisted airline import runs exist
- **WHEN** an authenticated administrator requests the airline imports page
- **THEN** a bounded page of safe run rows and pagination metadata is rendered

### Requirement: Administrator can start the configured airline import

The system SHALL allow an authenticated administrator to start one full
`wikidata_airlines` run using only server-defined source parameters and SHALL
reject a second run while the source already has queued or running work.

#### Scenario: Start an airline import

- **GIVEN** an enabled inactive airline import source
- **WHEN** an authenticated administrator submits the start action
- **THEN** one queued full run is created with that administrator as initiator

#### Scenario: Reject a concurrent airline import

- **GIVEN** an airline import run is queued or running
- **WHEN** an administrator submits another start action
- **THEN** no second run is created
- **AND THEN** an explanatory alert is returned

#### Scenario: Reject an unauthorized start

- **WHEN** a non-admin member submits the airline import start action
- **THEN** the action is denied
- **AND THEN** no import run is created
