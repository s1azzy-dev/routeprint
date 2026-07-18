## Why

Routeprint airports currently retain a two-letter country code without a
canonical country record, localized display names, or a foreign-key boundary.
The airport catalog needs a provider-neutral country/territory reference before
countries can be selected, displayed in the current `en` and `ru` locales, or
used to derive visited-country state for the map.

This is a Level 3 change: it introduces a durable shared-reference model,
source boundary, and map-boundary delivery decision that affect future airport
imports and map behaviour.

## What Changes

- Add canonical `countries` and localized `country_names` reference records for
  the countries and territories represented by OurAirports airport data.
- Add one composite country-catalog import. It downloads OurAirports
  `countries.csv` for membership and airport-compatible codes, plus Unicode
  CLDR territory names for `en` and `ru`, as independently attributable
  artifacts of one catalog package.
- Relate each `Place` (and therefore each `Airport`) to a canonical country,
  replacing the persisted free-standing country-code relationship through a
  staged, backfilled migration.
- Extend the existing protected Imports workspace with a Countries history page
  and start button that use the same safe, paginated operator flow as airport
  imports.
- Add a versioned, application-owned Natural Earth country-boundary asset keyed
  by country code for future browser-side visited-country highlighting.
- Record the source, provenance, fallback, boundary, and deferred-spatial-query
  decisions in an ADR.

## Capabilities

### New Capabilities

- `country-reference-catalog`: Canonical country/territory records and
  localized names with stable code-based lookup and fallback.
- `country-reference-import`: Idempotent composite reference ingestion from
  approved provider artifacts with provenance and diagnostic behaviour.
- `country-boundary-layer`: Versioned static country geometry that can be
  matched to a country code without a database geometry query.

### Modified Capabilities

- `place-and-airport-foundation`: Places and airports resolve their country
  through the canonical country reference rather than retaining an independent
  country-code field.
- `admin-imports-ui`: The protected Imports workspace exposes and starts the
  coordinated country-catalog refresh alongside airport imports.

## Impact

- New country models, migration, factories, interactor/source-adapter code,
  import-source configuration, protected admin controller/page, specs, and an
  ADR.
- `Place`, airport administration, and the existing OurAirports airport
  adapter change from accepting a persisted country code to resolving a
  country reference at the import/application boundary.
- A generated static frontend map asset and its provenance documentation are
  added; no visited-country UI, public API, spatial country lookup, region
  catalog, or runtime map service is introduced.
