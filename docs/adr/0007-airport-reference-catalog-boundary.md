# ADR 0007: Airport Reference Catalog Boundary

- Status: Accepted
- Decided: 2026-07-10
- Scope: The architectural boundary for Routeprint's global fixed-wing airport
  reference catalog, its identity, and its relation to travel history.

## Context

Routeprint is flight-first. Airport records are shared reference data used by
many users' travel segments; they are not user-owned records and are not an
airport-operations or regulatory system.

### Aviation identifiers in brief

- An **IATA location identifier** is an IATA-assigned three-letter commercial
  travel code. It supports reservations, ticketing, baggage, cargo, and travel
  distribution. It can identify an airport, metropolitan area, or intermodal
  point such as a rail station, so it is not a durable internal airport ID.
- An **ICAO location indicator** is a four-letter operational code used in
  flight operations and air-traffic systems. States formulate new indicators;
  ICAO checks them and publishes them in Doc 7910.
- IATA is an industry association, not an aviation regulator. ICAO establishes
  international standards, while national civil aviation authorities implement
  and enforce their own certification and operating rules.

Consequently, neither public code defines Routeprint's internal identity, and
Routeprint does not infer an airport's legal or safety status from a code.

## Decision

### Reference-catalog boundary

`Place` is the internal reference entity and `Airport` is its one-to-one
fixed-wing airport specialization. `Place.id` is the sole durable Routeprint
identity. IATA and ICAO codes are nullable lookup attributes: they are neither
primary keys nor foreign keys, and the database does not treat them as globally
unique historical identities.

The MVP catalog represents airport records usable as endpoints of fixed-wing
regular or charter flights. It excludes heliports, seaplane bases, and
balloonports. Closed airport records remain in the catalog as historical
reference data; later current-flight pickers must exclude them by default but
historical imports and travel segments may reference them.

### Persistence boundary

- `places.location` is a PostGIS `geography(Point, 4326)` with a GiST index.
- `places.name` is the canonical display fallback; localized names are stored
  in relational `place_names` rows.
- A place has a current/default IANA timezone and its verification metadata.
  Segment-local timezone snapshots and DST resolution remain governed by ADR
  0006; changing reference data never silently rewrites historical segments.
- PostgreSQL owns structural integrity and spatial storage. Application
  contracts and interactors own domain validation, lookup resolution, source
  conflict handling, and current-picker policy.

### External-data boundary

OurAirports or another provider is an input source, not Routeprint's domain
identity authority. Source IDs, source-specific types, checksums, snapshots,
mapping, duplicate candidates, and invalid-row handling belong to the separate
import subsystem under ADR 0003.

## Consequences

- A code change, withdrawal, or collision cannot change the identity of a
  historical airport reference.
- Future import rules must diagnose multiple active candidates for an IATA or
  ICAO lookup rather than silently merging records.
- The map remains user-scoped under ADR 0001; the global catalog is a lookup
  source, not a bulk map payload.
- Expanding to helicopter, seaplane, balloon, or other transport facilities
  requires an explicit product and catalog-scope decision.

## Non-Goals

- Airport certification, safety status, runway capability, slots, schedules,
  live operational status, or route authorization.
- Provider-row eligibility, code-conflict resolution, or import error policy.
- UI search ranking and current-flight picker behavior.

## References

- [IATA location identifiers](https://www.iata.org/en/iata-repository/pressroom/fact-sheets/fact-sheet-iata-location-codes/)
- [ICAO location indicators, Doc 7910](https://store.icao.int/en/location-indicators-doc-7910)
- [ICAO and State regulatory responsibilities](https://www.icao.int/about-icao/FAQs)
