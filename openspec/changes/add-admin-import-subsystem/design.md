## Context

Routeprint has a canonical, provider-neutral `Place`/`Airport` catalog and a
Solid Queue runtime, but no import persistence or execution code. ADR 0003
states the intended principles in brief, and ADR 0007 explicitly keeps
OurAirports IDs, raw rows, mapping, and invalid-row handling outside the
canonical catalog.

The first slice is a global admin-operated reference import. It begins with
OurAirports airports and must make later reference sources possible without
turning Routeprint into a generic ETL product. User-owned files, travel
segments, and admin UI are explicitly deferred.

## Goals / Non-Goals

**Goals:**

- Make every reference import durable, observable, idempotent, and retryable.
- Preserve source identity, raw input, normalized data, changed payload history,
  and the explicit link to an internal airport.
- Allow valid rows to progress while invalid or ambiguous rows stay staged with
  actionable diagnostics.
- Keep domain writes in explicit `yabi` interactors and PostGIS persistence in
  the established `Place`/`Airport` boundary.
- Use existing Rails, Solid Queue, Active Storage, PostgreSQL, and PostGIS
  facilities without a new dependency or service.

**Non-Goals:**

- Admin UI, routes, Inertia props, operational dashboards, or an authorization
  policy implementation for the future UI.
- User-owned imports, App in the Air, flight parsing, preview/review/apply, or
  travel-segment writes.
- Country and region domain models or ingestion of those OurAirports datasets.
- A generic source-to-domain mapping DSL, a generic polymorphic domain-link
  table, or a separate ETL deployment.

## Decisions

### 1. Use a bounded `Imports` namespace

Models live under `Imports`, backed by `import_` tables, with source-specific
interactors and jobs under `app/interactors/imports/**` and
`app/jobs/imports/**`. The common layer owns lifecycle, persistence, retry, and
diagnostic semantics. Each source adapter owns acquisition, parsing,
normalization, eligibility, matching, and its call to a domain apply
interactor.

`Imports` does not gain a configurable mapping language. A source adapter is
ordinary, testable Ruby code, and a domain write remains an ordinary use case.
This preserves a single module without hiding source-specific policy.

Alternative: one Rake task per source. Rejected because it cannot supply common
history, partial progress, safe retry, or provenance. A separate ETL service is
also rejected: the current workload does not justify a second deployment or a
second path into the domain.

### 2. Persist reference imports as sources, runs, items, records, and links

| Table | Responsibility | Key boundary |
| --- | --- | --- |
| `import_sources` | Stable definition of one provider dataset | unique `key`, provider/dataset metadata, fetch mode, enabled flag, attribution/license, non-secret config |
| `import_runs` | One immutable execution receipt | source, effective parameter/parser snapshot, optional initiating admin, `retry_of_run_id`, aggregate counters, terminal outcome |
| `import_run_items` | Independently claimable shard or chunk | unique `(run, item_kind, item_key)`, checkpoint, lease, attempts, item counters and error state |
| `import_artifacts` | Original downloaded source snapshot | checksum, source URL/metadata, capture time, private Active Storage attachment |
| `import_source_records` | Stable upstream record identity and current staged state | unique `(source, record_kind, external_uid)`, raw/normalized payloads, checksum, seen times, latest run |
| `import_record_snapshots` | Changed source-record versions | source record, run, checksum, payload snapshot, capture time |
| `import_issues` | Row- or item-level diagnostics | run/item/source record, stage, code, severity, sanitized detail, resolution state |
| `import_airport_source_links` | Provider-neutral mapping to the catalog | one source record to `airports.place_id`, match strategy, linked time |

Operational import tables use bigint primary keys. The airport source link uses a
UUID `airport_place_id` foreign key to `airports(place_id)`, because that is the
airport primary key. Database constraints enforce foreign keys, unique external
identity, unique item keys, a source record's single airport link, and at most
one active run per source. Application contracts and interactors own status
transitions, source eligibility, catalog matching, and error policy.

`ImportRun` retains small cross-source counters as first-class fields and puts
source-specific measurements in `stats`. It stores an effective configuration
and parser-version snapshot, never re-reads mutable runtime defaults as the
meaning of a delayed job.

`ImportArtifact` retains the complete raw response; `ImportSourceRecord` holds
the row-level raw and normalized representations needed for diagnosis and
replay. An artifact is private/internal even when its input is public reference
data. A record snapshot is created only when its checksum changes.

Alternative: source IDs and raw payload columns directly on `places` or
`airports`. Rejected because it couples canonical identity to one provider and
cannot represent multiple providers or payload history. A polymorphic generic
domain-link table is rejected because it weakens foreign-key integrity and
hides domain-specific matching rules.

### 3. Treat queue delivery as at-least-once and runs as immutable history

`Imports::StartRun` persists a queued run and its items in one transaction, then
enqueues one Solid Queue job per item on the `imports` queue. A job receives only
the run-item ID.

`Imports::ProcessRunItem` claims the row under a lock. A successful claim stores
an execution token and lease expiry; a duplicate delivery with a live lease is
a no-op. The processor checkpoints after bounded batches. Retrying a row is
safe because external identity, checksum, source record, domain link, and
domain apply behavior are idempotent; a checkpoint improves efficiency rather
than being the correctness mechanism.

When a worker disappears, stale claimed items are recoverable after lease
expiry. A run is finalized under a parent-row lock only after all items are
terminal. A failed or partially failed run stays terminal forever. An operator
retry creates a successor run with `retry_of_run_id` and a copied effective
snapshot, selecting the failed scope; it never rewrites the predecessor.

Cancellation is cooperative: a cancellation request prevents new item claims
and is observed between batches. It preserves completed work and terminal
history.

Alternative: reopen a failed run and reset its items. Rejected because it
destroys the history requested for operations and makes progress/error evidence
ambiguous. This intentionally differs from the older Wildwaters retry shape.

### 4. Keep dirty data in staging and diagnostics

The common pipeline permits a source item to complete with row-level issues.
Invalid, incomplete, or ambiguous records receive `ImportIssue` rows and remain
unresolved in `ImportSourceRecord`; they do not reach a domain apply interactor.
Issues retain an error code, stage (`acquire`, `parse`, `normalize`, `match`,
or `apply`), severity, and sanitized detail, not a raw exception dump.

The source-specific adapter decides whether a record is eligible for automatic
application. It cannot silently guess through an ambiguous catalog match. A
future admin UI can query unresolved records and issues, but that UI is not
defined by this change.

### 5. Implement `ourairports_airports` as the first adapter

`ourairports_airports` is seeded as a reference source. Its adapter preserves
the original dataset artifact, uses the provider's stable row ID as
`external_uid`, and normalizes only the fields required by the airport catalog.
IATA and ICAO codes remain lookup attributes, never source or Routeprint
identity keys.

The apply path is explicit:

1. reuse an existing airport source link when present;
2. otherwise accept only an unambiguous conservative catalog match, or create a
   new `Place` and `Airport` through a domain interactor;
3. persist the source link and match strategy in the same transaction;
4. update the linked catalog record only through that explicit path.

The adapter excludes facilities outside ADR 0007's fixed-wing airport scope.
It validates coordinates and timezone data before domain application. Longitude
and latitude are converted to the existing WGS84 `geography(Point, 4326)` via
the domain model; the importer does not implement its own spatial store.

An authoritative full snapshot can mark absent source records
`missing_upstream`, but it MUST NOT delete or detach a canonical airport. Closed
or historical airports remain referenceable.

### 6. Keep raw data and future operations private by default

The future admin entrypoint will authorize only administrators, but no HTTP
surface is added here. Import artifacts, raw payloads, and detailed issue
content are excluded from public, map, and future ordinary Inertia response
surfaces. Logs and persisted run errors contain stable IDs and sanitized error
codes only; they never include raw rows, credentials, signed blob URLs, or full
provider responses.

Source configuration records URLs and licensing/attribution metadata, not
credentials. If a future source requires credentials, its secure configuration
requires a separate security review and change.

### 7. Roll out without automatic catalog mutation

Migrations use explicit `up`/`down`, generated `db/structure.sql`, matching
foreign-key types, indexes, and no hand-edited schema dump. The initial source
definition is inserted idempotently. Deployment adds the subsystem and adapter
but does not run an import automatically.

Before production catalog data exists, a migration rollback can remove the
tables. After a real run, rollback is logical: disable the source, cancel active
work, and retain evidence rather than dropping provenance or catalog data.

## Risks / Trade-offs

- **Provider schema or content drift** → retain exact artifacts, checksum and
  parser version; convert unsupported rows into diagnostics rather than silently
  mapping them.
- **Duplicate delivery or a worker crash** → locked claim, lease recovery,
  checkpoints, unique identity, and idempotent domain links.
- **Large source files** → bounded run items and batch checkpoints; choose the
  partition size from measurements during the first adapter implementation.
- **Unbounded raw-data storage** → retain only source artifacts and changed
  record snapshots; document source licensing and retention before production
  scheduling.
- **Accidental catalog merge through public codes** → use a source link and
  conservative matcher; collision becomes an issue, not an overwrite.
- **Premature country/region abstraction** → retain no country/region domain
  data until product behavior defines its canonical target.

## Migration Plan

1. Add the import schema, models, source seed, factories, and focused tests.
2. Add lifecycle interactors and the Solid Queue item job, with no UI entrypoint.
3. Add the OurAirports airport adapter, fixtures, catalog apply path, and
   reconciliation behavior.
4. Expand ADR 0003 and update `CHANGES.md` with the implemented boundary.
5. Run a controlled first import only after code and operational review; add the
   future admin action in a separate change.

## Open Questions

- Which artifact URL/version signal and import cadence should the initial
  OurAirports source use in production?
- What measured item partition size best balances Solid Queue throughput and
  recovery time for the airport dataset?
- What retention period and licensing notice are appropriate for raw reference
  artifacts before scheduled production imports begin?
- A future change must define the admin UI, authorization policy, issue
  resolution workflow, and sources for countries or regions.

ADR 0003 is updated by this Level 3 change; a second import ADR is unnecessary
because ADR 0003 already owns the subsystem boundary.
