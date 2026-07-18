## Context

`places.country_code` currently stores a normalized two-letter value without a
canonical country record. The OurAirports airport adapter copies
`iso_country` into that field, while the application supports `en` and `ru`
locales and already uses a relational localized-name pattern for places.

The existing import subsystem (ADR 0003) preserves provider artifacts, source
records, runs, and explicit source-to-domain links. Its first adapter is
OurAirports airports. The country catalog is global reference data, not
user-owned data. The repository also contains an unused 110m country GeoJSON
asset derived from archived `world-atlas`; it has numeric IDs, does not cover
every airport territory as a separate feature, and is not a database source of
truth.

## Goals / Non-Goals

**Goals:**

- Persist a provider-neutral catalog of every country or territory accepted by
  the OurAirports airport source, including the `XK` Kosovo code.
- Persist English and Russian display names with the same locale/fallback
  semantics as `PlaceName`.
- Make `Place` refer structurally to a country and make the airport adapter
  resolve its incoming code through that catalog.
- Preserve separate provenance, retry, and diagnostics boundaries for the
  OurAirports membership source and CLDR localization source.
- Deliver country boundaries as a versioned browser asset keyed by country
  code, without adding country polygons to the operational database.

**Non-Goals:**

- Visited-country UI, travel-segment aggregation, a public map endpoint, or a
  country selection/admin CRUD screen.
- Regions/subdivisions, capitals, flags, currencies, demographics, or a claim
  about political sovereignty beyond the confirmed airport-territory scope.
- Runtime third-party map services, vector tiles, PMTiles, or a spatial
  point-in-country API.
- Automatic acceptance of a new external country code without an approved
  catalog refresh.

## Decisions

### 1. Use a canonical `Country` plus relational `CountryName`

`Country` has a Routeprint UUID identity, required unique uppercase `code`,
canonical fallback `name`, and the source continent code. `code` is the
airport-compatible two-letter territory code, not a claim that every value is
an official ISO assignment: `XK` is explicitly valid because it is present in
the confirmed OurAirports membership set.

`CountryName` has one `(country_id, locale)` row per enabled application
locale. `Country#name_for(locale)` follows `Place#name_for(locale)`: the
localized name is returned when present, otherwise `Country#name`. Current
catalog application requires `en` and `ru`; adding a locale later requires an
explicit source input and catalog refresh.

Alternative: names in JSONB on `countries`. Rejected because locale uniqueness,
normalization, fallback, and locale expansion already have a relational
project pattern in `place_names`.

### 2. Model the relationship at `Place`, not `Airport`

`Place` receives `belongs_to :country`; `Airport` continues to obtain its
country through `airport.place.country`. A second foreign key on `airports`
would duplicate data and could drift. Incoming OurAirports `iso_country`
remains a source-normalization value only and is resolved before the canonical
place write.

Alternative: retain `places.country_code` indefinitely and join by code in
queries. Rejected because it cannot provide a structural relationship, makes
country-name lookup an application convention, and permits orphan codes.

### 3. Use one composite country-catalog import

One `country_catalog` import source owns one run, one work item, and three raw
artifacts: the OurAirports countries CSV and CLDR territory JSON for `en` and
`ru`. The source represents Routeprint's catalog recipe; it does not claim that
the upstream data has one provider. Every artifact records its provider, dataset,
URL, configured version, checksum, and parser diagnostics. Source records retain
their provider-specific external UID and record kind.

One processor downloads and stages all artifacts, validates that the package is
complete, then transactionally upserts canonical countries and names with their
source links. A missing or invalid artifact fails the sole item and run, leaving
canonical records unchanged. Retrying the run remains idempotent and may reuse
already captured artifacts.

Operationally and technically this is one import: no child runs, follow-up job,
or `refresh_id`. The admin lists `country_catalog` runs and starts the same
composite recipe. Its index follows the airport-import page: newest-first
paginated history, source key, mode, allowlisted parameters, status, counters,
and timestamps. The button posts no client-controlled source parameters, and
the start wrapper requires the enabled inactive catalog source and records the
current administrator as initiator. `Admin::BaseController` remains the sole
authorization boundary; raw artifacts, records, and diagnostics never enter
Inertia props.

Alternative: make OurAirports the sole source. Rejected because it has only a
common English name and cannot supply the required Russian translation.

Alternative: two independent source runs coordinated by a refresh identifier.
Rejected because it creates a distributed state machine for one atomic catalog
operation, with ambiguous partial-refresh state and extra operator actions.

### 4. Version static Natural Earth geometry outside PostgreSQL

The map layer is an application-owned generated asset with a documented Natural
Earth release, checksum, and source URL. Its feature properties include
`countryCode`, so MapLibre can match a visited-country code without joining on
names or M49 IDs. The generation contract verifies that every catalog country
has exactly one displayable boundary or fails with an explicit mapping issue;
the `XK` mapping is maintained explicitly.

The asset resolution is selected only after this coverage check: it must cover
the confirmed airport-territory set, then be deterministically simplified for
browser delivery. The old 110m asset is not accepted merely because it exists.

Alternative: store MultiPolygons in `countries`. Rejected for the current
need: map highlighting needs no server-side spatial predicate, would enlarge
and version operational data, and would require geometry validation/indexing
without a query consumer. If a future feature requires `ST_Contains`, country
area calculations, or database-side joins, create a separate PostGIS change
using `geometry(MultiPolygon, 4326)`, a GiST index, source versioning, and
validity checks.

### 5. Use a staged, non-network migration

The first migration creates the country tables and adds a nullable
`places.country_id` foreign key/index while retaining `country_code`. A release
operation runs the catalog refresh and backfills places by their existing code;
it reports every unmatched value. Application writes then resolve a country and
populate `country_id`.

Only after an audited zero-unmatched backfill does a follow-up migration make
the foreign key required and remove `country_code`. Migrations never fetch
OurAirports, CLDR, or map geometry over the network.

## Risks / Trade-offs

- [Provider code or locale mismatch] → stage both raw snapshots, fail before
  canonical writes, and retain the previous catalog.
- [Incomplete catalog package] → the processor applies only after all three
  artifacts stage and validate successfully.
- [Existing orphan place code] → report it during backfill and defer the
  `NOT NULL`/column-removal migration until resolved.
- [Boundary coverage or disputed-boundary mismatch] → verify country-code
  coverage during generation, document the Natural Earth release, and keep map
  geometry separate from catalog identity.
- [Payload growth at a higher map resolution] → simplify deterministically and
  measure browser asset size before accepting the generated output.
- [Sensitive data exposure] → reference sources and country boundaries are
  global data; raw source artifacts and diagnostics remain inside the import
  boundary and never enter ordinary Inertia props.

## Migration Plan

1. Add the proposal's ADR, country tables, import-source metadata, models,
   adapters, and focused tests.
2. Deploy the additive schema and run the one country-catalog refresh action.
3. Backfill `places.country_id`, inspect unmatched codes, and update the
   airport adapter/admin path to resolve canonical countries.
4. After production data is complete, enforce the required foreign key and
   retire the duplicate code column in a follow-up migration.
5. Add the protected Countries imports page and its request/component coverage.
6. Generate the verified static boundary asset and expose it only when the
   future map feature consumes it.

Rollback before step 4 removes only the new association/use case and leaves
the existing country code intact. The imported catalog and source-run history
are retained; no canonical airport is deleted by a source refresh.

## Open Questions

- Which Natural Earth release/resolution passes complete airport-territory
  coverage within the accepted browser payload budget?
