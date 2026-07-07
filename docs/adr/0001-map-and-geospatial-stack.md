# ADR 0001: Map And Geospatial Stack

## Status

Accepted

## Decision

Routeprint uses PostgreSQL/PostGIS for spatial storage and geospatial operations,
Rails JSON/GeoJSON endpoints for bounded map data delivery, and MapLibre GL JS
for browser map rendering.

## Consequences

- Store geographic source-of-truth data in WGS84/SRID 4326.
- Test spatial behavior against real PostGIS.
- Keep MVP map payloads compact GeoJSON.
- Defer vector tiles, PMTiles, real aircraft tracks, and separate geospatial
  services until measured need.
