# Tasks

## 1. Route data

- [x] 1.1 Add owner-scoped route aggregation and verify isolation, counts, complete history, and current coordinates in the Home request specs.

## 2. Geometry and map

- [x] 2.1 Build and test spherical arcs, seam cutting, Mercator clipping, label placement, and wrapped bounds in frontend fixtures.
- [x] 2.2 Render and refresh the overlay, verify map lifecycle in frontend tests, and update CHANGES.md and TODO.

## 3. Integration

- [x] 3.1 Verify rendering across world copies, label placement and collision, and measure a large synthetic overview.
- [x] 3.2 Run strict OpenSpec validation and make verify.

## Verification notes

- Headless Chromium verified the seam before and after panning, two distinct
  overlapping routes, and one visible count where the labels collided.
- A 1,000-pair synthetic overview used 147 KB of route JSON (69 KB gzip) and
  drew its first routes 390 ms after navigation in the local browser run.
  A separate container benchmark generated 1,000 arcs in 63–92 ms.

## Workflow follow-up

- Sync the home-map-shell baseline and archive after verification.
