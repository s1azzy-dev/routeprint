## Why

Routeprint currently exposes an Inertia/React home page but has no actual map
renderer. The first map slice should establish a real, reusable MapLibre
container on `/` so later flight routes, GeoJSON data, and map controls have a
working frontend surface.

This is a Level 2 specified feature. It implements the existing frontend/map
direction and does not introduce a new durable architecture decision, so no
new ADR is required.

## What Changes

- Add the pinned `maplibre-gl` npm dependency and keep its JavaScript/CSS in the
  Vite-built application assets.
- Add a feature-owned React `RouteMap` component with explicit container and
  MapLibre lifecycle cleanup.
- Render the home route as a full-viewport map using a temporary public demo
  style for the initial browser smoke surface.
- Render a small local GeoJSON `LineString` demonstration route so the map
  proves application-owned line layers, not only basemap loading.
- Keep MapLibre loading feature-local instead of importing it from the global
  application entrypoint.
- Preserve the existing frontend test contract while adding focused map-shell
  behavior coverage.

## Capabilities

### New Capabilities

- `home-map-shell`: A full-viewport MapLibre map with a visible route line on
  the public home route.

### Modified Capabilities

- None. The current bootstrap page has no established product requirement to
  preserve beyond returning the `Home/Show` Inertia page.

## Impact

- Frontend dependency graph and lockfile: `package.json`, `package-lock.json`.
- Inertia home page and frontend component tests.
- New Routeprint map component and local map styling.
- No Rails routes, controllers, database schema, PostGIS queries, or user data
  contracts change in this slice.
- Browser runtime still needs the selected demo style's external style/tile
  resources; production basemap selection remains outside this initial shell.
