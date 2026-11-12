# Proposal

## Why

The home map shows the basemap while the owner's recorded flights are only
visible in history. Show those flights as airport-to-airport routes on the map.

## What Changes

- Load the signed-in owner's complete flight history grouped by airport pair.
- Draw great-circle routes and count labels for repeated pairs, including routes
  that cross the antimeridian or leave the visible Mercator latitude range.
- Fit the initial view to the visible routes and show the basemap alone for
  guests and accounts without drawable routes.

## Capabilities

### Modified Capabilities

- `home-map-shell` gains the personal flight-route overview.

## Impact

Level 2. The Home Inertia response and MapLibre component implement the existing
decision in ADR 0010. Scope covers the overview and aggregate route counts.
Statistics, route selection, sharing, and aircraft tracks are outside scope.
Verify owner isolation, geometry boundaries, and rendering with world copies.
