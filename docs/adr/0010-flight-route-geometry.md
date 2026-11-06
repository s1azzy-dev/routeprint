# ADR 0010: Flight Route Geometry

- Status: Accepted
- Decided: 2026-11-06
- Scope: Route identity, map data delivery, and browser-derived flight arcs.

## Context

Flight history records the endpoints of each flight. `TravelSegment` references
the departure and arrival places, and `Place.location` stores their WGS84
coordinates. A route line is a spherical approximation between those airports.
The history records do not contain the aircraft's flown path.

[ADR 0001](0001-map-and-geospatial-stack.md) assigns authorization and data
delivery to Rails, spatial filtering to PostGIS, and rendering to MapLibre.
The personal travel map covers the owner's complete flight history. The map
feature is pending in [TODO](../TODO.md).

## Decision

### Route identity and delivery

Rails scopes flights to the authorized owner, then groups them by the unordered
pair of endpoint `Place` IDs. The group key is the two IDs sorted into a
consistent order. SVO → IST and IST → SVO share one key. Names and airport codes
are display labels that can change or be absent. Each flight keeps its original
direction and identity in history.

Rails supplies compact JSON with airport coordinates and a flight count per
pair. The overview loads all groups from the owner's history independently of
map pan and zoom. The count belongs to the airport pair, even when rendering
the line requires multiple pieces.

### Build the geographic arc

An application-owned, pure frontend module takes the normalized WGS84 endpoints
in `[longitude, latitude]` order and samples the shorter great-circle arc on a
sphere. The module depends on neither MapLibre nor a geospatial library. Use
the pair's canonical endpoint order so either direction yields the same line.
Preserve the airport endpoints in the geographic arc. MapLibre receives the
sampled vertices because a GeoJSON line only connects the points it is given.
Interpolating longitude and latitude directly, including with a Bézier curve,
would produce a different path. Arc vertices remain transient display data.
[RFC 7946 §3.1.1](https://www.rfc-editor.org/rfc/rfc7946.html#section-3.1.1)

Spherical interpolation can be expressed with endpoint unit vectors `a` and
`b`. The shorter angular distance is `α = atan2(|a × b|, a · b)`. For an
ordinary pair, the tangent toward `b` at `a` is `u = normalize(a × b) × a`.
The position at angle `θ` along the arc is `a cos θ + u sin θ`, for
`0 ≤ θ ≤ α`. Convert the sampled vectors back to longitude and latitude.
Subdivide long spans by angular length and refine where the projected curve
departs visibly from the chord. Apply the projected error budget at the
intended overview zoom range with a vertex cap per pair. This keeps short
routes cheap and gives long or strongly curved routes more samples. Preserve
the airports and any clipping or seam intersections when reducing detail.
Choose the numeric tolerance and cap using visual fixtures and measurements.

Check that both endpoints contain finite coordinates in the WGS84 ranges.
Coincident points have no visible arc. Exact antipodes admit multiple equally
short arcs. Both cases have a zero cross product, so detect them before
normalizing the great-circle normal. Near antipodes, the shorter arc is unique,
but its plane is sensitive to small changes in the inputs. Preserve it when it
can be computed reliably. If coordinates are invalid or a stable arc cannot be
derived, omit that line and retain the underlying flights. An arbitrary
intermediate point can change the path, including for a nearly antipodal pair.

### Clip to the Mercator latitude limit

Retain the portions of the arc within Web Mercator's usable latitude range
(about `±85.05113°`). Find the latitude boundary crossings along the arc and
end each visible portion at its crossing. A route may leave the visible range
and re-enter it, even when both airports are well within the range. Split the
angular interval at the latitude extrema and solve for the boundary in each
monotone interval using the vertical component of the arc vector. This catches
short excursions between samples and distinguishes a tangent touch from a
crossing. At the exact pole longitude is undefined. Clip the hidden portion
before using longitude continuity for the visible pieces.

A gap across the hidden polar section is expected. Joining its ends or
clamping all out-of-range vertices to the boundary would draw a false segment
along the map edge. The geographic arc remains available independently of
this display clipping.

### Cross the antimeridian without a false segment

Within a visible piece, follow adjacent samples using equivalent longitudes
in the nearest world copy. For example, `[179.8, -17]` to `[-179.7, -17]`
spans about `0.5°` in longitude when the second point is represented at
`180.3°`. Wrapping each sample independently without cutting the line would
make the renderer connect opposite map edges through the center. Longitudes
outside the canonical range remain local to the renderer and camera.
[MapLibre antimeridian example](https://maplibre.org/maplibre-gl-js/docs/examples/display-line-that-crosses-180th-meridian/)

Give MapLibre normalized GeoJSON. Cut each crossing at the intersection of the
arc with the antimeridian. In the arc's unit-vector coordinates, this is a
crossing of `y = 0` on the `x < 0` side of the sphere. End one part at `+180°`
and start the next at `−180°` at the same latitude, or reverse the signs for
westbound traversal. A route that starts, ends, or runs along the seam needs
only the boundary representation on the side where it is drawn. Drop
zero-length pieces. Use `LineString` for a single visible part and
`MultiLineString` for multiple parts of one route. Keep its ID and count on
the feature.

Enable `renderWorldCopies` so the two sides of the cut can meet in adjacent
copies. A line ending at the seam and its matching continuation must have no
visible gap in that view. Duplicate copies are display instances of one route.
[RFC 7946 §3.1.9](https://www.rfc-editor.org/rfc/rfc7946.html#section-3.1.9),
[MapLibre world copies](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/#renderworldcopies)

If the camera fits a route, use the extent of the full visible arc, including
its intermediate vertices, in a consistent world copy. Bounds from normalized
endpoints alone can choose a near-global view at the antimeridian or crop a
high-latitude arc. Any endpoint markers shown with that view must align with
the same displayed copy of the route.

### Draw and distinguish routes

One shared MapLibre GeoJSON source and a shared line layer draw the static
Mercator overview. The source carries one logical feature per pair, with one
or more line parts as needed. A visible crossing between different routes is
an overlap of independent features. It creates no airport, transfer, or new
route. Routes that share an airport meet at the same point. Distinct routes
can also overlap along a segment and retain their own identity and count.
MapLibre styling and interaction can distinguish a selected route without
altering the geographic line. Route details remain available through the
flight history when overlaps make the map hard to read or operate.

For groups with at least two flights, use a single label anchor on visible
geometry and the aggregate count as its text. Derive the anchor from a visible
span of the arc so polar clipping cannot place it in the gap and seam cutting
cannot create extra labels. Use a shared MapLibre symbol layer with collision
handling enabled. A count appears where it fits alongside other labels and is
shown at most once per route within a world copy.
[MapLibre symbol collision rules](https://maplibre.org/maplibre-style-spec/layers/#text-overlap)

Keep arc generation independent of the map instance. The browser updates
source data when the route data changes. Pan and zoom use the existing
geometry. Recompute when a route or an endpoint coordinate changes. If a style
reload removes the custom sources and layers, reinstall them with the latest
route data.

### Geometry and renderer verification

Unit verification covers endpoint order, bidirectional grouping, stable arcs,
and clipping boundaries. Useful fixtures include a normal transatlantic arc,
HND–SFO, a short crossing from `179.8°` to `−179.7°` in both orders, an endpoint
exactly on the seam, ANC–OSL, coincident points, and exact and near antipodes.
Assert seam endpoints and a small longitude span in continuous coordinates.
For a polar excursion, assert the boundary crossings and the absence of a
segment along the clipped edge.

Browser verification covers behavior that coordinates alone cannot prove.
Inspect seam continuity while panning through a world copy and when focused on
the route. Check for missing or duplicate count labels on multipart and dense
routes, and check that overlapping routes retain their own identity. Use a
large synthetic history to measure payload size, arc generation, and first
render separately.

## Alternatives Considered

- **Build arcs on the server.** This would allow a viewport query to test the
  same geometry it delivers. The full-history overview needs no spatial
  selection, and endpoint data is more compact than sampled lines.
- **Persist sampled arcs.** A stored line can be indexed, but it duplicates
  derived data and would need rebuilding after airport coordinate or algorithm
  changes. Revisit storage only if profiling shows on-demand work is a bottleneck.
- **Use Turf for the geographic arc.** Turf provides great-circle sampling and
  can return split lines. The renderer still needs polar clipping and control
  over cut points and camera bounds. A small pure module keeps those operations
  on the same spherical parameterization. [Turf `greatCircle`](https://turfjs.org/docs/api/greatCircle)
- **Send an unwrapped `LineString` to MapLibre.** This works for a continuous
  seam crossing with world copies. Splitting keeps source coordinates
  normalized and lets the same multipart representation express polar gaps.

## Consequences

- Browser work scales with the number of unique airport pairs. Measure payload
  size and first render for large histories before considering an explicit date
  filter. The initial overview has no flight-count cutoff.
- Projection and style changes can use the same geographic arc. Globe,
  decorative curvature, gradients, and animation remain separate from geometry.
- The travel-map OpenSpec change will define acceptance scenarios and detailed
  interaction for map selection. Sampling and visual values can be tuned against
  the geometry and renderer checks above.
