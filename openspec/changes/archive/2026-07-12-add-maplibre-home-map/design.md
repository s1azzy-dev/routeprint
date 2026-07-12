## Context

The current `Home/Show` page is an Inertia/React placeholder. Routeprint already
uses Vite, strict TypeScript, React Testing Library, and a feature-owned map
boundary, but `maplibre-gl` is not yet part of the dependency graph.

This slice is frontend-only. It does not add Rails map data, a GeoJSON
endpoint, PostGIS queries, or user-owned travel records. The visible route is a
small local fixture used to prove the rendering pipeline.

## Goals / Non-Goals

**Goals:**

- Bundle MapLibre through the pinned npm dependency and Vite, not a runtime
  CDN.
- Keep MapLibre initialization, cleanup, and map-specific layer setup inside a
  reusable `RouteMap` component.
- Render `/` as a full-viewport map with a visible GeoJSON line.
- Keep the map module feature-local and test it with a mocked MapLibre runtime
  under the existing jsdom/Vitest setup.
- Provide one small React-owned reset-view control as the pattern for future
  map actions.

**Non-Goals:**

- No backend map endpoint, authentication, user data, or authorization change.
- No interactive user drawing plugin, routing engine, clustering, or markers.
- No production basemap provider decision; the demo style is only a smoke-test
  dependency and remains replaceable.
- No database or PostGIS artifact: no spatial storage, query, or geometry
  operation is implemented by this change.

## Decisions

### Use the native `maplibre-gl` package

Add `maplibre-gl` as an exact production dependency and import it from the map
component together with its CSS. This keeps the full native API available for
GeoJSON sources, line layers, controls, and future MapLibre plugins without
adding a second React map abstraction for the first map surface.

`react-map-gl` remains a viable later option if several pages need declarative
map composition, but it is not required for this single native map boundary.

### Own the imperative lifecycle in `RouteMap`

The component keeps a DOM container ref and a native MapLibre instance ref. A
single effect creates the map, adds navigation controls, registers the load
handler, and removes the map on cleanup. This is compatible with React strict
mode and prevents duplicate WebGL/map instances during development remounts.

### Keep the route as a GeoJSON source and line layer

The initial fixture is added after the map's `load` event as a GeoJSON source
and `line` layer. Future server-provided `FeatureCollection<LineString>` data
can replace the source data without changing the page/container contract.

### Keep product controls in React

MapLibre's built-in navigation control handles zoom and compass. The reset-view
button is rendered by React in an absolutely positioned overlay and calls the
native map instance through the component's ref. This preserves normal button
semantics and leaves room for shadcn-based controls later.

### Keep MapLibre out of the global entrypoint

The dependency is imported only by `RouteMap`, not by
`app/frontend/entrypoints/application.tsx`. Inertia/Vite can then keep the
map code attached to the page that uses it instead of making the application
bootstrap own the map runtime.

## Risks / Trade-offs

- [External demo style] → Keep the URL in one map-local constant and document
  it as temporary; replace it with a production style catalog in a later
  change.
- [WebGL cannot be exercised by jsdom] → Mock the MapLibre module in component
  tests and use the production build as the bundling proof; browser smoke
  coverage can be added when the local browser harness is available.
- [MapLibre adds a large browser dependency] → Keep the import feature-local
  and avoid adding drawing/routing dependencies until those behaviors are
  requested.
- [Map lifecycle callback can outlive a React cleanup] → Guard initialization
  with the container ref and always call `map.remove()` from the effect cleanup.

## Migration Plan

1. Add the exact npm dependency and regenerate the lockfile through the project
   frontend install target.
2. Add the component and focused Vitest coverage.
3. Replace the home placeholder with the full-viewport map composition.
4. Run frontend checks, the home request spec, strict OpenSpec validation, and
   the applicable fast verification gate.

Rollback is a normal revert of the dependency, component, page, test, and
OpenSpec change files; no database or persistent data migration is involved.

## Open Questions

None for this implementation slice. Production basemap selection and
interactive drawing are intentionally deferred.
