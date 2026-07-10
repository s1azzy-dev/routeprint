## 1. Import foundation and structural persistence

- [x] 1.1 Write failing model and migration specs for source definitions, runs,
  run items, source records, snapshots, diagnostics, and airport source links.
- [x] 1.2 Add SQL-forward primary-database migrations with matching foreign-key
  types, unique identity/index boundaries, and generated schema output; do not
  add domain workflow or code-format `CHECK` constraints.
- [x] 1.3 Add the `Imports` model namespace, associations, local validations,
  factories, and an idempotent `ourairports_airports` source definition seed.
- [x] 1.4 Run the narrow model and migration specs against the real PostgreSQL
  and PostGIS database until green.

## 2. Durable run orchestration

- [x] 2.1 Write failing interactor and job specs for start, active-run exclusion,
  item-only job arguments, progress aggregation, and terminal finalization.
- [x] 2.2 Implement start, claim, checkpoint, complete/fail, cancel, and
  finalize interactors using row locks, an execution lease, and persisted
  effective input snapshots.
- [x] 2.3 Add the thin Solid Queue `imports` job and prove duplicate delivery of
  a succeeded or live-leased item does not repeat domain work.
- [x] 2.4 Write failing retry and stale-recovery specs, then implement successor
  runs linked by `retry_of_run_id` and recovery of only expired active items.
- [x] 2.5 Run the focused interactor/job specs and `make verify-fast` after the
  orchestration slice is green.

## 3. Provenance, artifacts, and diagnostics

- [x] 3.1 Write failing specs for artifact checksum retention, source-record
  identity, normalized/raw payload preservation, and changed-payload snapshots.
- [x] 3.2 Implement private artifact storage through the existing Active Storage
  boundary and source-record/snapshot persistence without raw payloads in logs
  or ordinary response serializers.
- [x] 3.3 Write failing mixed-validity batch specs, then implement staged
  unresolved records and sanitized `ImportIssue` diagnostics that allow later
  valid rows to continue.
- [x] 3.4 Add focused security/logging coverage and run the relevant specs plus
  `make security`.

## 4. OurAirports airport adapter

- [x] 4.1 Add sanitized OurAirports fixture files and write failing parser,
  normalization, eligibility, and source-identity specs.
- [x] 4.2 Implement the source-specific acquisition, parser, normalizer, and
  bounded item processing path using provider row ID as external identity.
- [x] 4.3 Write failing airport-link and catalog-apply specs for existing links,
  unambiguous matching, ambiguous code collisions, and newly created airports.
- [x] 4.4 Implement the explicit airport apply interactor and
  `ImportAirportSourceLink`, preserving `Place`/`Airport` as provider-neutral
  canonical records.
- [x] 4.5 Write failing PostGIS and invalid-row specs, then implement WGS84 point
  persistence, timezone/eligibility diagnostics, and no-write behavior for
  excluded facilities.
- [x] 4.6 Write failing full-snapshot reconciliation specs, then mark missing
  upstream source records without deleting linked airports or places.
- [x] 4.7 Run the focused adapter/model/interactor specs and `make verify-fast`.

## 5. Documentation and final verification

- [x] 5.1 Reconcile ADR 0003, this OpenSpec change, `CHANGES.md`, and source
  metadata with the implemented behavior; update artifacts before any intentional
  divergence.
- [x] 5.2 Run `bin/openspec validate --all --strict` and resolve all artifact
  validation errors.
- [x] 5.3 Run the focused RSpec groups, `make verify-fast`, `make security`, and
  the full `make verify`; record any environmental blocker exactly.
- [x] 5.4 Defer admin UI/routes, authorization request specs for that UI,
  OurAirports countries/regions, and all user-owned imports to separate approved
  changes.
