# ADR 0001: Map And Geospatial Stack

## Status

Accepted

## Context

Routeprint is flight-first and map-first: the primary product surface is a
personal travel map backed by user-owned flight history. The application is a
Rails monolith with PostgreSQL and PostGIS, and it needs an interactive browser
map without making a proprietary hosted map SDK or external geospatial service
the owner of core product behavior.

The MVP should keep the map stack replaceable, inspectable, and cheap to run.
Rails owns authorization, filtering, and response contracts. PostGIS owns
spatial predicates. The browser owns interaction and rendering.

## Decision

Routeprint uses an open, replaceable map stack built around PostgreSQL/PostGIS,
Rails JSON/GeoJSON endpoints, and MapLibre GL JS. Do not make a proprietary map
SDK, runtime CDN, hosted vendor API, vector-tile service, or external geospatial
platform the default owner of the MVP map architecture.

### Technology Boundary

- PostgreSQL with PostGIS owns spatial storage, indexing, and bounded spatial
  filtering.
- Geographic source-of-truth data uses WGS84/SRID 4326.
- Rails owns authorization, user scoping, route/filter parameters, and compact
  JSON/GeoJSON response contracts.
- Inertia/React owns page composition and browser orchestration.
- MapLibre GL JS is the browser renderer for interactive maps.
- MapLibre JavaScript and CSS are application-owned runtime assets, not
  runtime CDN dependencies.

### Data Delivery

- MVP map data is delivered as compact GeoJSON over bounded HTTP requests.
- Map requests must include a bounded viewport or equivalent server-approved
  envelope before returning user travel geometry.
- List and map views should share one query model whenever they represent the
  same filter state, so visible records and visible geometry do not diverge.
- Rails responses should select only the fields needed by the map surface.
- Route geometry and airport points remain user-scoped response data.

### Basemap Boundary

- Basemap styles and tile provider choices belong in an application-owned
  catalog, not scattered through page code.
- Provider replacement should not require replacing MapLibre, PostGIS, or the
  Rails query path.
- Attribution and provider availability are operational concerns of the chosen
  catalog entries.

Vector tiles, PMTiles, real aircraft tracks, live tracking, and separate
geospatial delivery services are deferred. They require measured need and a new
architecture decision, not an implicit extension of this ADR.

## Alternatives Considered

### Mapbox GL JS Or Google Maps

Both are mature, but they would make a vendor-controlled SDK, hosted terms, or
commercial API boundary central to the product's main screen.

### Leaflet

Leaflet is simpler, but Routeprint expects WebGL-style rendering and a map stack
that can grow into route geometry, clustering, and richer layers without
changing the browser renderer.

### OpenLayers

OpenLayers is capable, but its broader GIS-oriented API surface is heavier than
the current MVP needs.

## Consequences

- Test spatial behavior against real PostGIS.
- Keep MVP map payloads compact and user-scoped.
- Keep map/list synchronization in the Rails query layer rather than duplicating
  filter semantics in the browser.
- Keep MapLibre assets and dependency freshness under application control.
- Defer vector tiles, PMTiles, real aircraft tracks, live tracking, and separate
  geospatial services until measured need.
- Replacing a tile provider should be a catalog/configuration change, not a
  product architecture rewrite.
