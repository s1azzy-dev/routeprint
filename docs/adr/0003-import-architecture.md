# ADR 0003: Import Architecture

- Status: Accepted
- Decided: 2026-07-07
- Refined: 2026-07-10
- Scope: Admin reference-import lifecycle, provenance, raw-data retention,
  idempotency, retry history, diagnostics, and source-to-domain boundaries.

## Context

Routeprint needs repeatable reference-data imports, beginning with the global
OurAirports airport catalog. The canonical `Place`/`Airport` model must not take
on provider identity, raw rows, import execution state, or source-specific
eligibility policy. Background work already uses Rails and Solid Queue.

Imports may later grow to additional reference datasets, but user-owned files,
flight imports, and the admin UI require separate product decisions. A
cross-cutting subsystem is needed now because a throwaway import script would
lose history, idempotency, diagnostics, and provenance from its first use.

## Decision

### Module boundary

Routeprint uses a bounded `Imports` namespace inside the Rails monolith.
Common import code owns source definitions, runs, run items, raw artifacts,
source records, snapshots, diagnostics, and lifecycle orchestration.
Source-specific code owns acquisition, parsing, normalization, eligibility, and
matching. Canonical domain writes pass through explicit `yabi` interactors;
models do not become an ETL orchestration layer.

The subsystem is intentionally not a generic mapping DSL or a separate service.
Each source remains ordinary Ruby code with source-specific tests.

### Persistence and provenance

An `ImportSource` represents one provider dataset, not a canonical domain
entity. It records stable metadata such as key, dataset, fetch mode, enabled
state, licensing/attribution, and non-secret configuration.

Each start creates an `ImportRun` with a durable effective configuration and
parser snapshot. Runs own independently processable `ImportRunItem` records,
aggregate counters, sanitized errors, and immutable terminal history. Raw input
artifacts are retained privately through the existing Active Storage boundary.

`ImportSourceRecord` persists the stable upstream identity as source, record
kind, and external UID, together with raw and normalized payloads, a checksum,
and seen/change metadata. Changed content produces an `ImportRecordSnapshot`.
`ImportIssue` persists sanitized row- or item-level diagnostics. JSONB is
reserved for source-specific/import-oriented data rather than canonical
searchable fields.

Domain mapping uses explicit link tables. The first is
`ImportAirportSourceLink`, which connects a source record to
`airports.place_id`, records the match strategy, and protects Routeprint's
canonical identity from provider-code changes or collisions. Generic
polymorphic domain links are not used.

### Execution, idempotency, and retry

Solid Queue jobs receive only an import-run-item ID and claim work under a row
lock with a persisted execution lease and checkpoint. Delivery is treated as
at-least-once: duplicate delivery, a retry, or a stale-worker recovery must not
duplicate source records, links, or domain writes.

One source has at most one queued or running run. Item progress and errors are
durable. Parent finalization occurs under a run lock only after all items are
terminal. A failed or partially failed run remains immutable; an operator retry
creates a successor run linked through `retry_of_run_id`, using the persisted
input and failed scope. Cancellation is cooperative between batches and also
preserves history.

### Dirty data and reference catalog policy

Invalid, incomplete, excluded, or ambiguously matched rows remain staged with
an issue and do not silently write to the canonical catalog. A valid row can
continue even when another row in the item has an issue. Raw input and detailed
diagnostics remain internal and never belong in public, map, or ordinary
Inertia response surfaces or in logs.

`ourairports_airports` is the first adapter. Its stable provider row ID is the
external identity; IATA and ICAO codes are lookup attributes only. The adapter
accepts only the ADR 0007 fixed-wing catalog scope, applies coordinates through
the existing WGS84 `geography(Point, 4326)` place boundary, and diagnoses bad
coordinates, timezones, or ambiguous matches. A full authoritative snapshot
can mark a source record missing upstream but never deletes a linked canonical
airport, including a closed historical airport.

### Deferred boundaries

The future admin action must authorize administrators, but admin routes, UI,
Inertia props, and issue-resolution UX are outside this decision's current
implementation slice. User-owned uploads, App in the Air, travel-segment
imports, country/region domain models, and any credentialed source need
separate OpenSpec changes.

## Consequences

- Reference imports are observable, provenance-aware, private by default, and
  safe to retry.
- Domain tables remain provider-neutral and retain historical references even
  when an upstream source changes or removes a row.
- Solid Queue uses persisted work definitions rather than mutable runtime
  configuration or large job arguments.
- Supporting a new source requires a source adapter and explicit domain link or
  apply policy; it does not extend an unbounded generic mapper.
- The initial implementation adds operational tables and tests, but no admin UI
  or user import behavior.

## Alternatives Considered

### One Rake task or script per source

Rejected because it cannot provide persistent progress, partial recovery,
snapshot history, or a common diagnostic contract.

### Reopen a failed run in place

Rejected because it rewrites the history that operators need to inspect. A
linked successor run makes retries auditable.

### Store external IDs and raw fields on airports

Rejected because it couples the canonical airport identity to one provider and
cannot support multiple sources or changed payload history.

### Separate ETL service or a generic mapping framework

Rejected because the current scale does not justify another deployment or a
second application style, and source-specific policy must stay explicit.
