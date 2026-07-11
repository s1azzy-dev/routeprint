## ADDED Requirements

### Requirement: Reference imports create durable, source-scoped executions
The system SHALL represent each admin reference-import start as a new import run
with its source, effective configuration snapshot, parser version, initiation
metadata, and one or more persisted run items before it enqueues work.

#### Scenario: Start a reference import
- **GIVEN** an enabled reference source with a valid effective configuration
- **WHEN** the import start use case is called
- **THEN** it creates a distinct queued run and its queued items atomically
- **AND THEN** each item's job is enqueued on the `imports` queue using only the
  persisted item identifier

#### Scenario: Reject a concurrent source execution
- **GIVEN** a source has a queued or running import run
- **WHEN** another start is requested for that source
- **THEN** the request fails without creating a second active run or enqueueing
  duplicate work

### Requirement: Run progress and terminal status are durable
The system SHALL persist progress, attempts, item status, item
errors, and aggregate run outcome so that an operator can inspect an import
after its job process has ended.

#### Scenario: Complete all items successfully
- **GIVEN** all items of a running run complete successfully
- **WHEN** the final terminal item is finalized
- **THEN** the parent run is marked succeeded with aggregate counters and a
  finish timestamp

#### Scenario: Finish with a failed item
- **GIVEN** one or more items have failed and no item remains active
- **WHEN** the parent run is finalized
- **THEN** it is marked partially failed and retains the completed-item counts
  and sanitized failure information

### Requirement: Item execution uses ordered fail-fast phases
The system SHALL process one item through ordered phases: acquire the complete
artifact, parse the complete source file, persist all raw source records, and
only then normalize, match, and apply canonical records. A phase failure SHALL
stop later phases and mark the item failed.

#### Scenario: Persist raw rows before canonical apply
- **GIVEN** a valid source file containing multiple provider rows
- **WHEN** the item starts processing
- **THEN** all raw rows are persisted before normalization or canonical apply
  begins
- **AND THEN** a failure during apply leaves the raw rows available for
  diagnosis while canonical changes from that apply phase are rolled back

### Requirement: Queued processing is safe under at-least-once delivery
The system SHALL limit concurrent jobs for the same run item to one and make
processing idempotent across duplicate job delivery and retries.

#### Scenario: Deliver a completed item again
- **GIVEN** a run item has already succeeded
- **WHEN** its job is delivered again
- **THEN** it performs no domain apply work and leaves the recorded result
  unchanged

### Requirement: Retry preserves completed run history
The system SHALL keep a terminal run immutable and represent an operator retry
as a separate successor run linked to the failed predecessor.

#### Scenario: Retry only failed scope
- **GIVEN** a partially failed run with succeeded and failed items
- **WHEN** the retry use case is called
- **THEN** it creates a new run with `retry_of_run_id` set to the predecessor
- **AND THEN** it creates work only for the failed scope using the predecessor's
  effective input snapshot
- **AND THEN** the predecessor's status, timestamps, counters, and errors stay
  unchanged

### Requirement: Abandoned running items are maintained separately
The system SHALL keep periodic cleanup of items that remain running beyond an
operational threshold outside the import execution path. The maintenance policy
is deferred from this change.

#### Scenario: Defer abandoned-item cleanup
- **GIVEN** a run item remains `running` beyond the future operational threshold
- **WHEN** the current import execution path processes jobs
- **THEN** it does not use an application-level lease or cancellation branch
- **AND THEN** a separate maintenance job/change is responsible for cleanup
