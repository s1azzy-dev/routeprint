## Why

Routeprint's flight history, map, search, and future flight entry need a
canonical representation of real-world airport places before those features
can be built. The foundation should preserve geographic and timezone semantics
without coupling the domain schema to a future import provider.

## What Changes

- Add canonical `places` records with WGS84 point geometry, geographic context,
  and IANA timezone metadata.
- Add localized `place_names` records with a canonical place-name fallback.
- Add airport-specific records with current operational status and public lookup
  codes.
- Add structural foreign keys and indexes, while keeping code resolution and
  catalog policy in the application/import boundary.
- Add Rails models, factories, model specs, and generated schema coverage.
- Keep import batches, raw source records, source identifiers, runways,
  frequencies, and navaids outside this change.

## Capabilities

### New Capabilities

- `place-and-airport-foundation`: Canonical places, localized names, and airport
  persistence contracts for flight-first Routeprint behavior.

### Modified Capabilities

None.

## Impact

- Adds `places`, `place_names`, and `airports` database tables and indexes.
- Adds `Place`, `PlaceName`, and `Airport` Active Record models.
- Establishes the fixed-wing airport-reference boundary used by future travel
  segments, map queries, manual entry, and the separate import subsystem.
- No new gem, external service, user-owned resource, or public endpoint is
  introduced.

This is a Level 3 change because the persistence and geospatial boundaries are
durable architecture decisions; ADR 0007 records the adopted design.
