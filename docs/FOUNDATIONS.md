# Foundations

This document owns stable product, architecture, domain, data, and database
boundaries. It is not a roadmap, status report, command list, or implementation
scratchpad.

Use it when a task needs to answer:

- what Routeprint is and is not;
- which domain concepts are canonical;
- where business logic, data access, and UI orchestration belong;
- which database, privacy, import, and PostGIS rules must stay consistent.

Workflow, commands, permissions, and verification live in
`docs/DEVELOPMENT.md`. Security and testing policy lives in
`docs/QUALITY_SECURITY.md`.

## Product Boundary

Routeprint is a production-minded Rails/PostGIS monolith for personal travel
history and travel maps, starting with flight history.

Decision order:

1. User value.
2. Data ownership and privacy.
3. Maintainability and consistency.
4. Delivery speed.
5. Future extensibility without MVP bloat.

Current product stance:

- Flights are the only active public transport mode in the MVP.
- Travel segments are the canonical movement unit.
- A flight is a travel segment with flight-specific details.
- The map, import, manual entry, statistics, and export are the active MVP
  surfaces.
- Confirmed future work is ordered in `docs/TODO.md` and becomes behavior only
  through an OpenSpec change.
- Web and JSON/GeoJSON entrypoints must share the same domain/use-case layer
  when both exist.

Do not turn the MVP into:

- a generic travel planner;
- a native mobile app;
- a live flight tracker;
- a social network;
- an AI trip assistant;
- an offline-first app;
- a public API platform;
- a separate ETL product;
- a vector-tile service before measured need.

## Architecture Boundary

Routeprint is one Rails monolith serving web UI, JSON/GeoJSON responses, admin
tools, imports, exports, and background jobs.

Stable architecture rules:

- Prefer current Rails conventions and existing project patterns.
- Controllers orchestrate HTTP only.
- Models own persistence, associations, scopes, normalization, and local
  invariants.
- Business use cases live in `app/interactors` and use the canonical `yabi`
  style.
- Business use cases are explicit, fail-fast pipelines: validate real input,
  keep `call` focused on orchestration, pass state through method arguments,
  and stop on the first failure.
- One interactor represents one meaningful use case, not one private pipeline
  step. Prefer focused private methods before extracting another interactor;
  inject nested interactor dependencies instead of calling constants directly.
- Queries that are not business use cases may live in `app/queries`.
- Authorization stays explicit through policies for user-owned resources or a
  dedicated guard for bounded admin surfaces.
- The application-owned business frontend uses Vite, Inertia Rails, React,
  TypeScript, Tailwind, and shadcn/ui under ADR 0002 and ADR 0004.
- New application-owned business and admin UI should use this stack instead of
  introducing ERB, Hotwire, Stimulus, or ViewComponent pages.
- Shared UI should use shadcn primitives and Routeprint wrappers before adding
  page-local custom controls.
- Rails continues to own web routing, sessions, CSRF, authorization, I18n, and
  business use cases.
- Dedicated JSON/GeoJSON endpoints are allowed for bounded dynamic data such as
  map payloads.
- Background work uses the Rails/Solid Queue stack unless a concrete need
  justifies otherwise.
- Add leases, cancellation, checkpoints, compensating flows, or custom locking
  only for a demonstrated execution requirement; default to simple state
  transitions and existing database/queue guarantees.
- Queued use cases tolerate duplicate delivery through durable state and keep
  exceptional stale-work cleanup outside the normal execution pipeline.
- Do not introduce parallel service/interactor/API response styles.

Concrete cross-cutting decisions live in ADRs:

- Map and geospatial stack: `docs/adr/0001-map-and-geospatial-stack.md`
- Business frontend architecture:
  `docs/adr/0002-business-frontend-architecture.md`
- Import architecture: `docs/adr/0003-import-architecture.md`
- UI component foundation: `docs/adr/0004-ui-component-foundation.md`
- Time zone and flight schedule time handling:
  `docs/adr/0006-time-zone-and-flight-schedule-time-handling.md`

## Domain Boundary

Canonical domain areas:

- Identity and authentication.
- User-owned travel data.
- Places and airports.
- Airlines and flight metadata.
- Travel segments.
- Flight details.
- Trips/grouping.
- Imports and source provenance.
- Map data.
- Statistics.
- Exports.
- Admin and operational tooling.

Unimplemented domain layers are tracked in `docs/TODO.md`, not here.

Canonical movement model:

- `TravelSegment` is the root movement entity.
- `flight` is the only active `transport_mode` for MVP user-facing behavior.
- Flight-specific fields belong in `flight_details`.
- Shared searchable/filterable fields belong on first-class tables, not inside
  generic metadata.
- Future transport modes require an explicit product decision before
  user-facing behavior, routes, filters, imports, or abstractions are added.

Canonical place model:

- `Place` represents selectable real-world locations such as airports, cities,
  stations, ports, or custom places.
- `airport` is the active MVP place kind.
- The MVP airport reference catalog covers fixed-wing airports; closed records
  remain available for historical travel, while heliports, seaplane bases, and
  balloonports require a later product decision.
- Airport-specific source fields belong in `airports`.
- Stable public identifiers, names, coordinates, timezones, and country codes
  should be first-class fields.

Import model:

- Imports are not throwaway scripts and not a generic ETL product.
- Import flows must be idempotent, provenance-aware, diagnosable, privacy-safe,
  and safe to retry.
- Preserve source identity, raw source records, normalized payloads, checksums,
  snapshots, source/domain links, and import reports where applicable.
- Source-specific parsing belongs under import-specific code; domain writes
  should pass through explicit domain/apply interactors.

## Data Ownership And Privacy

Every user-owned travel object must have explicit ownership and authorization
coverage. Never trust client-provided ownership fields.

Private by default:

- User profile.
- Travel segments and trips.
- Imported files and source payloads.
- Exact timestamps.
- Booking references.
- Seat data.
- Boarding passes.
- Future trip data.
- Profile statistics unless explicitly shared.

Public or unlisted sharing requires explicit product behavior, visibility
states, and tests. Public surfaces must exclude booking references, raw source
metadata, seats, internal IDs, and future-trip details unless explicitly
allowed.

## Data And Geospatial Boundary

- PostgreSQL 18 and PostGIS 3.6 are first-class dependencies.
- Store geographic source-of-truth data in WGS84/SRID 4326.
- Airport coordinate lookup, map filtering, and route geometry belong in
  database-backed queries/services, not controllers.
- Add spatial indexes for spatial columns.
- Test PostGIS behavior against the real database.
- Use compact, user-scoped, filterable, privacy-safe GeoJSON payloads.
- Generate great-circle-like route lines from airport coordinates for MVP.
- Handle antimeridian crossing explicitly when route geometry is implemented.
- Do not introduce vector tiles, PMTiles, real aircraft tracks, external flight
  APIs, or a separate geospatial service until measured payload/query limits
  require it.
- Use `jsonb` only for genuinely source-specific, import-oriented, or
  subtype-specific data that is not a core searchable field.

## Database Boundary

- Use `structure.sql` as the canonical schema dump.
- Never edit `db/structure.sql` by hand.
- Prefer SQL-forward migrations inside Rails migration wrappers.
- Use explicit `up` and `down`.
- Prefer PostgreSQL `uuidv7()` primary keys for main domain tables.
- `bigint` is acceptable for internal operational tables when it is the simpler
  fit.
- Foreign key types must match referenced primary keys.
- Default to explicit primary keys, foreign keys, `NOT NULL`, and justified
  indexes.
- Add geospatial indexes for location-backed lookups.
- Use `CHECK` only for true storage-level invariants.
- Keep business validation in the application layer.
- Keep naming consistent and within PostgreSQL identifier limits.

## Extension Rule

Extend from the current product and codebase, not from speculative future
platform ideas. Add abstractions only when an implemented use case needs them or
an ADR records the decision.
