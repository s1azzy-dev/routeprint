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
The system SHALL persist progress, attempts, checkpoints, item status, item
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

### Requirement: Queued processing is safe under at-least-once delivery
The system SHALL make processing a run item idempotent across duplicate job
delivery, retries, and recovery after a worker failure.

#### Scenario: Deliver a completed item again
- **GIVEN** a run item has already succeeded
- **WHEN** its job is delivered again
- **THEN** it performs no domain apply work and leaves the recorded result
  unchanged

#### Scenario: Recover a stale claimed item
- **GIVEN** a run item has a running status and an expired execution lease
- **WHEN** stale-work recovery runs
- **THEN** the item becomes eligible for a new claim using its persisted
  checkpoint
- **AND THEN** the replacement execution increments its attempt count without
  creating a second run

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

### Requirement: Cancellation is cooperative and auditable
The system SHALL stop unclaimed or checkpoint-reached work after cancellation
is requested while retaining completed work and terminal history.

#### Scenario: Cancel a running import
- **GIVEN** a running reference import with active and queued items
- **WHEN** cancellation is requested
- **THEN** queued items are not newly claimed and active items stop at a safe
  checkpoint
- **AND THEN** the run and affected items record a cancelled terminal outcome
