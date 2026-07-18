# ADR 0008: Country Reference Catalog And Boundary Delivery

- Status: Proposed
- Decided: 2026-07-16
- Scope: Global airport-territory identity, localized country names, source
  provenance, place relationship, and country-boundary delivery for Routeprint.

## Context

Routeprint imports airports from OurAirports, whose two-letter country codes
include airport territories and the non-ISO `XK` Kosovo code. `Place` currently
stores that code without a canonical relationship or localized country names.
The future map must highlight visited countries, but its boundary asset is
currently an unused low-resolution JSON derived from an archived source and is
not sufficient as a durable identity boundary.

## Decision

Routeprint owns a provider-neutral `Country` catalog with a Routeprint UUID and
an airport-compatible two-letter `code`; its membership is the confirmed set of
countries and territories supplied by OurAirports `countries.csv`, including
`XK`. `CountryName` stores localized names by `(country_id, locale)`, initially
for `en` and `ru`, with the country fallback name used when no translation is
available.

`Place` belongs to `Country`; `Airport` gets its country through its place.
OurAirports `iso_country` remains source data that an adapter resolves to a
country before writing a place. It is not a Routeprint identity or a foreign
key copied onto the airport.

One composite `country_catalog` import source and run capture the OurAirports
membership CSV and Unicode CLDR `en`/`ru` territory JSON as separately
attributable provider artifacts. Its sole work item commits canonical
country/name changes only after the complete package validates. Artifacts,
records, checksums, retries, and diagnostics remain governed by ADR 0003.

Country geometry remains a versioned, application-owned Natural Earth browser
asset keyed by `countryCode`. It is not stored in PostgreSQL while the product
only needs browser-side highlighting. A future server-side spatial-country
feature requires a dedicated PostGIS decision/change with validated
`geometry(MultiPolygon, 4326)` and a GiST index.

## Consequences

- The country catalog exactly supports airport territories rather than asserting
  a broader geopolitical model.
- Country localization and map matching use stable codes, never display names.
- One composite import preserves provider-level provenance and retry evidence,
  while operators use one refresh action.
- The initial migration is additive; the free-standing place country code is
  retired only after an audited catalog refresh and complete backfill.
- Static geometry must prove full catalog coverage before it is shipped.

## Alternatives Considered

### OurAirports as the only country source

Rejected because it cannot supply the required Russian localized names.

### CLDR as the only country source

Rejected because the product boundary is explicitly the set of territories
accepted by the airport source, including its `XK` exception.

### Country polygons in PostgreSQL now

Rejected because no current product path needs a spatial predicate; it would
add geometry validation, indexing, and versioning to operational data without a
query consumer.
