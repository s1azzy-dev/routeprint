## Context

Routeprint has no domain persistence for airports yet. The product foundations
define `Place` as the canonical real-world location and `airport` as the active
MVP place kind. PostgreSQL/PostGIS owns geographic storage and filtering, while
future import adapters must remain separate from the canonical domain schema.

The change must also support the accepted airport-local time model: a place may
have an IANA timezone, its provenance, and the time at which that value was last
verified. A missing timezone is diagnosable rather than silently fabricated.

## Goals / Non-Goals

**Goals:**

- Persist canonical places with a single indexed WGS84 point.
- Persist a canonical fallback name plus one localized name per locale.
- Persist airport-specific lookup codes and operational status without copying a
  source-provider schema.
- Enforce structural and spatial storage invariants in PostgreSQL while keeping
  domain vocabularies, formats, and workflow validation in the application
  layer.
- Establish a stable foundation for future flights, maps, search, and imports.

**Non-Goals:**

- Import batches, source records, raw payloads, reconciliation, or provenance
  links.
- Runways, frequencies, navaids, countries, or region reference tables.
- Flight segments, airport search endpoints, map payloads, or frontend UI.
- Historical timezone assignments or automatic timezone enrichment.
- Heliports, seaplane bases, balloonports, runway/frequency data, and airport
  operations data.

## Decisions

### 1. Split `places` from `airports`

`places` owns shared real-world location data: canonical fallback name,
geography, municipality, country/region/continent codes, and timezone metadata.
`airports` owns aviation-specific data and uses `place_id` as both primary key
and foreign key. This preserves the project domain boundary and leaves room for
future place kinds without putting airport fields on every place.

### 2. Keep names relational

`places.name` is the required canonical fallback and is not declared to be a
particular language. `place_names` stores localized display names with a unique
`(place_id, locale)` pair. UI selection and fallback belong to presenters or
queries; translations are not stored in JSONB.

### 3. Store one spatial source of truth

`places.location` uses `geography(Point, 4326)` and a GiST index. Incoming
longitude/latitude pairs are converted to the point in database/application
boundary; duplicate numeric coordinate columns are not stored. The geography
column's type modifier enforces point geometry and SRID 4326.

### 4. Keep timezone evidence explicit

`time_zone` stores an IANA identifier and may be null until resolved. `time_zone_source`
describes the evidence or method, and `time_zone_verified_at` records when the
current value was last checked. It is not an ordinary row-update timestamp.
Timezone validation and metadata consistency use the existing TZInfo dependency
and application validation; the database does not hard-code the evolving tzdata
catalogue or the workflow around verification.

### 5. Limit the MVP catalog to fixed-wing airport references

The airport table represents only fixed-wing airport records. It stores an
application-owned `operational_status` so closed records remain referenceable
for historical travel. Source types, size classification, scheduled-service
flags, and all non-fixed-wing facilities remain in the future import contract,
not the canonical schema.

### 6. Use explicit partial uniqueness for public codes

`iata_code` and `icao_code` are normalized and validated in the application as
lookup values. They are not internal identity and are not globally unique
database constraints: public codes can change, be withdrawn, or collide with
historical data. The import contract will diagnose ambiguous active candidates.
Provider-specific identifiers are intentionally out of this change and will be
owned by the import subsystem.

### 7. Keep business rules out of the database

The migration contains no domain `CHECK` constraints for allowed kinds,
statuses, code formats, non-blank text, country formats, or timezone metadata.
PostgreSQL owns primary keys, foreign keys, required structural columns, the
PostGIS type, and indexes. Rails models provide the current application-level
validation; future create/update interactors or contracts will own
use-case-specific validation.

### 8. Migration and verification boundary

The migration follows the existing SQL-forward `up`/`down` pattern, uses
`uuidv7()` and `timestamptz`, and never edits `db/structure.sql` directly.
Model specs cover associations, normalization, validation, and fallback-name
behavior. A real PostgreSQL/PostGIS test database verifies the spatial column,
SRID, foreign keys, uniqueness, and GiST index.

## Risks / Trade-offs

- [Unresolved timezone] → Keep the place record diagnosable with nullable
  timezone metadata; future flight-entry behavior must reject or explicitly
  resolve airports without a usable zone.
- [Canonical fallback name is not locale-tagged] → Treat it as a fallback only;
  localized UI reads `place_names` first and can add a locale later without a
  schema migration.
- [Code reassignment or source conflicts] → Treat IATA and ICAO as lookup values
  rather than immutable identity; the future import subsystem will own
  reconciliation.
- [Spatial migration failure or rollback] → Use explicit reversible SQL and
  generate the schema dump through Rails after migration verification.
- [Future place kinds expand `kind`] → Keep current validation limited to the
  implemented airport foundation; adding another kind requires a separate
  behavior change rather than speculative tables.

## Migration Plan

1. Create `places`, `place_names`, and `airports` with structural foreign keys,
   indexes, and PostGIS storage.
2. Generate `db/structure.sql` through the documented Rails/Make workflow.
3. Run model and migration-backed PostGIS specs.
4. Roll back by dropping `airports`, `place_names`, and `places` in dependency
   order; no existing user-owned data is changed because these tables do not yet
   exist.

## Open Questions

None for this change. Import provenance and airport facility detail are
explicitly deferred to separate changes.

An ADR is required and created as
`docs/adr/0007-airport-reference-catalog-boundary.md` because the global
reference-catalog boundary, place/airport identity, localization boundary, and
PostGIS storage shape are durable architecture decisions.
