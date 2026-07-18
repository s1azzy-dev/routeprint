## 1. Country Catalog Persistence

- [x] 1.1 Add failing model specs for `Country`, `CountryName`, localized-name fallback, and the `Place` country association.
- [x] 1.2 Add explicit SQL-forward additive migrations for `countries`, `country_names`, source-link tables, and nullable indexed `places.country_id`; regenerate `db/structure.sql` through Rails.
- [x] 1.3 Implement country models, normalization, relational locale validation, associations, factories, and focused model specs.
- [x] 1.4 Add the staged backfill/audit use case and specs that resolve legacy place country codes without network access in migrations.

## 2. Composite Country-Catalog Import

- [x] 2.1 Replace the two source runs with one `country_catalog` source, run,
  work item, and artifact-level provenance.
- [x] 2.2 Reuse source parsers and normalizers in one composite processor that
  downloads and stages all three artifacts.
- [x] 2.3 Apply countries and localized names inside the composite processor
  only after the complete package validates; remove refresh coordination.
- [x] 2.5 Make the airport apply path resolve a canonical country, preserve a structured failure for unknown codes, and update its focused specs.
- [x] 2.6 Update protected `Admin::Imports::CountriesController` request
  coverage and history to expose only `country_catalog` runs with safe props.
- [x] 2.7 Update the catalog start wrapper and request coverage for one queued
  composite run and one work item, with initiator tracking.
- [x] 2.8 Add the `Admin/Imports/Countries/Index` Inertia page and component coverage reusing the established airport-import table, button, empty state, pagination, and current-navigation behaviour.

## 3. Static Boundary Asset

- [ ] 3.1 Select and record a Natural Earth release/resolution that covers the full airport-territory catalog; document its license, URL, checksum, and explicit `XK` mapping.
- [ ] 3.2 Add a deterministic generation workflow that emits an application-owned code-keyed boundary asset and fails for missing or ambiguous catalog mappings.
- [ ] 3.3 Add focused generation/asset checks for `countryCode` properties, full catalog coverage, and browser-size output; leave visited-country UI and dynamic spatial queries out of scope.

## 4. Documentation, Migration Completion, And Verification

- [ ] 4.1 Update ADR 0008 from proposed to accepted when the implemented source, association, and boundary decisions match this design; update `docs/adr/README.md` and `CHANGES.md`.
- [ ] 4.2 After the initial refresh has zero unmatched place codes, add the follow-up migration/specs that require `places.country_id` and retire `places.country_code`.
- [ ] 4.3 Run focused model/import/migration specs, `make agent-verify-fast`, `bin/openspec validate --all --strict`, and `make verify-fast`; run `make verify` before publication.
