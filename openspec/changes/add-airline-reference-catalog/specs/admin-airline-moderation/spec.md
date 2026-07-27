## ADDED Requirements

### Requirement: Airline moderation is restricted to administrators

The system SHALL expose airline moderation history and mutations only to
authenticated administrators.

#### Scenario: Member opens moderation

- **WHEN** an authenticated non-admin member requests the airline moderation
  workspace
- **THEN** the request is denied or redirected without exposing submission
  audit

#### Scenario: Guest submits a moderation action

- **WHEN** a visitor without an authenticated session submits an airline review
  action
- **THEN** the request is redirected to sign in
- **AND THEN** no airline state changes

### Requirement: Administrators can inspect bounded pending submissions

The system SHALL render a newest-first paginated moderation table containing
pending airline fields, original submission evidence, submitter audit when
available, candidate matches, and timestamps without exposing unrelated user or
travel data.

#### Scenario: Open pending moderation

- **GIVEN** pending airlines exist
- **WHEN** an administrator opens airline moderation
- **THEN** a bounded page of pending rows and pagination metadata is rendered
- **AND THEN** each row includes the evidence needed to review that candidate

#### Scenario: No pending airlines exist

- **WHEN** an administrator opens an empty moderation queue
- **THEN** an accessible empty state is rendered

### Requirement: Administrator can edit a pending candidate

The system SHALL allow an administrator to correct a pending airline's current
name, designators, country, and operational evidence without overwriting the
immutable original submission.

#### Scenario: Save valid corrections

- **WHEN** an administrator submits valid corrections for a pending airline
- **THEN** the candidate fields are updated atomically
- **AND THEN** the original submission remains available in audit history

#### Scenario: Reject invalid corrections

- **WHEN** an administrator submits malformed current airline data
- **THEN** no partial correction is persisted
- **AND THEN** validation errors are returned

### Requirement: Administrator can approve or reject a pending airline

The system SHALL let an administrator approve a valid pending airline or reject
an invalid candidate. Each terminal decision SHALL record reviewer and review
time.

#### Scenario: Approve a pending airline

- **WHEN** an administrator approves a valid pending airline
- **THEN** its review state becomes approved
- **AND THEN** it remains globally selectable without the unverified label

#### Scenario: Reject a pending airline

- **WHEN** an administrator rejects a pending airline
- **THEN** its review state becomes rejected
- **AND THEN** it is excluded from new selection without being deleted

### Requirement: Administrator can merge a pending duplicate

The system SHALL let an administrator merge a pending airline into an approved
target in one transaction, move all currently supported references, record the
target, and make the source unselectable.

#### Scenario: Merge a pending duplicate

- **GIVEN** a pending airline duplicates an approved airline
- **WHEN** an administrator confirms the approved target
- **THEN** supported references move to that target atomically
- **AND THEN** the source becomes merged and records the target

#### Scenario: Roll back a failed merge

- **WHEN** any reference cannot be moved during merge
- **THEN** the entire merge is rolled back
- **AND THEN** the pending source and its references remain unchanged

#### Scenario: Reject an invalid merge target

- **WHEN** an administrator selects a pending, rejected, merged, or system
  placeholder target
- **THEN** the merge is rejected without changing either airline

### Requirement: Protected system airline cannot enter moderation

The system SHALL exclude the `unknown_airline` record from the moderation queue
and reject every moderation action targeting it.

#### Scenario: Attempt to review the system airline

- **WHEN** an administrator submits approve, reject, edit, or merge for the
  system airline
- **THEN** the action fails without changing the record
