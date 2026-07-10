## 1. Red Tests And Factories

- [x] 1.1 Add Place, PlaceName, and Airport factories plus model specs for
  associations, normalization, validations, localized names, fallback data,
  timezone metadata, and code uniqueness.
- [x] 1.2 Run the narrow model specs and record the red/green evidence; the
  initial infrastructure blocker and the later matcher correction were kept
  explicit.

## 2. Persistence And Models

- [x] 2.1 Add an explicit SQL-forward reversible migration for `places`,
  `place_names`, and `airports`, including UUID primary keys, foreign keys,
  constraints, partial code indexes, the PostGIS geography column, and GiST
  index.
- [x] 2.2 Implement Place, PlaceName, and Airport models using the existing
  Active Record normalization, validation, and association patterns.
- [x] 2.3 Run the narrow model specs until green and inspect the generated
  schema through the Rails/Make workflow.

## 3. Documentation And Integration

- [x] 3.1 Add a dated `CHANGES.md` entry describing the canonical place,
  localized-name, airport, and PostGIS persistence foundation.
- [x] 3.2 Confirm no import provenance, source identifiers, runway, frequency,
  navaid, flight, map endpoint, or frontend behavior was introduced.

## 4. Verification

- [x] 4.1 Validate the change with `bin/openspec validate --all --strict`.
- [x] 4.2 Run the relevant model specs, `make verify-fast`, and the applicable
  final project verification gate from `docs/DEVELOPMENT.md`.

## 5. Boundary Correction

- [x] 5.1 Remove domain `CHECK` constraints and business defaults from the
  migration; retain only structural database integrity and PostGIS storage
  invariants.
- [x] 5.2 Regenerate the schema, rerun model specs and project gates, and update
  the OpenSpec/ADR evidence for the corrected application/database boundary.

## 6. Reference Catalog Scope

- [x] 6.1 Reframe ADR 0007 around airport-reference architecture, IATA/ICAO
  identity, regulatory boundaries, and the relationship to the existing map,
  import, and timezone ADRs.
- [x] 6.2 Limit the airport persistence model to fixed-wing references, retain
  closed records, and defer source-specific classification and non-fixed-wing
  facilities to the future import/catalog change.
- [x] 6.3 Regenerate the schema and rerun OpenSpec plus project verification.
