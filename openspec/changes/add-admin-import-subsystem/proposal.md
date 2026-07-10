## Why

Routeprint needs repeatable reference-data imports, beginning with the global
OurAirports airport catalog. One-off scripts cannot safely preserve provenance,
raw input, progress, failure state, or the mapping from an external record to a
canonical `Place`/`Airport`.

This is a Level 3 change: it introduces a durable, cross-cutting subsystem that
will be shared by later admin reference sources without making external source
schemas part of the product domain.

## What Changes

- Add an `Imports` subsystem for admin-operated reference-data imports.
- Persist source definitions, immutable import runs, independently processed
  run items, source records, changed-payload snapshots, raw input artifacts,
  and per-record diagnostics.
- Use Solid Queue jobs that receive only a persisted run-item identifier,
  report durable progress, and are safe to retry after failure or duplicate
  delivery.
- Preserve external identities and create explicit domain-specific mapping
  tables instead of adding source identifiers to canonical domain tables.
- Implement `ourairports_airports` as the first source adapter and map its
  eligible records to the existing airport catalog through an explicit source
  link.
- Keep terminal run history immutable: an operator retry creates a new run
  linked to the failed predecessor rather than rewriting it.
- Expand ADR 0003 with the confirmed persistence, execution, retry, raw-data,
  and domain-boundary decisions.

### Scope

- Admin/reference imports only.
- The future admin action may create a run, but admin routes, UI, Inertia props,
  and operational screens are not part of this change.
- Invalid or ambiguous reference rows remain staged with diagnostics; they do
  not silently modify the canonical catalog.

### Non-Goals

- User-owned uploads, App in the Air, CSV flight imports, preview/review/apply
  flows, and travel-segment writes.
- A canonical country or region domain model, or OurAirports country/region
  ingestion before a product need defines their domain targets.
- A generic field-mapping DSL, separate ETL service, external queue system, or
  automatic correction of historical travel data.

## Capabilities

### New Capabilities

- `reference-import-orchestration`: source/run/item lifecycle, Solid Queue
  execution, durable progress, stale-work recovery, cancellation, and immutable
  retry history for admin reference imports.
- `reference-import-provenance`: raw artifact retention, external source-record
  identities, normalized payloads, checksums, snapshots, diagnostics, and
  explicit domain mapping boundaries.
- `ourairports-airport-import`: idempotent import of eligible OurAirports
  airport records into Routeprint's canonical airport catalog.

### Modified Capabilities

- None.

## Impact

- New `Imports` models, migrations, interactors, jobs, factories, fixtures,
  and focused specs.
- A domain-specific airport source-link table plus a catalog apply interactor;
  `places` and `airports` remain canonical and provider-neutral.
- Existing Solid Queue and Active Storage are used; no dependency or external
  service is added.
- Queue idempotency, raw-data access boundaries, PostGIS point persistence, and
  retry/recovery behavior require focused verification before implementation.
