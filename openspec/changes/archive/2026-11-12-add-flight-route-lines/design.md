# Design

## Context

`docs/adr/0010-flight-route-geometry.md` defines the
server/browser boundary and the route geometry.

## Decisions

- Reuse the existing TravelSegment policy scope on Home. Aggregate flight counts
  by canonical UUID pair in PostgreSQL before joining the two WGS84 places.
  Return just the pair ID, two coordinates, and count in Inertia props.
  The response uses no-store caching. A separate endpoint would add a request
  to fetch the same page data. Grouping hydrated flight records in Rails would
  allocate objects proportional to the number of flights.
- Parameterize the shorter spherical arc with orthogonal vectors. Solve for
  crossings of the Mercator limits and antimeridian in angular coordinates.
  Sample visible intervals with a four-degree maximum step and refine for a
  half-pixel projected error target at zoom five, subject to a per-route vertex
  cap. One fixed step would spend vertices on straight spans and undersample
  more curved ones.
- Use shared line and count sources and layers. Each pair contributes one line
  feature and at most one point on its longest visible line part. Use normal
  MapLibre label collision handling and promote the string route ID from a
  feature property to preserve it in the renderer. Reapply data after a style
  reload and update sources when props change. Fit the first drawable overview
  from all visible parts, excluding the largest uncovered longitude gap so the
  initial view can straddle the antimeridian.
- Check the owner boundary in request specs, geometry with deterministic
  fixtures, and the renderer in a browser. Include a large synthetic fixture
  to measure payload and browser costs.

## Rollout

The change uses the existing schema and dependencies. A code revert removes
the overlay and the Home prop. ADR 0010 already covers the architecture.
