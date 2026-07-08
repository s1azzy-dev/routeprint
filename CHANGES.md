# Changes

## 2026-07-08

- Added password registration, sign-in, sign-out, signed user-session cookie
  handling, current-session resume, last-seen throttling, suspended-user
  rejection, and a minimal protected dashboard for the auth foundation.
- Added the first authentication foundation implementation slice: account,
  identity, and user-session schema; core auth models; token digest helpers;
  password policy validation; email normalization; factories; and model/lib
  specs.
- Switched Rails schema dumps to SQL format and generated `db/structure.sql`
  plus `db/queue_structure.sql`.

## 2026-07-07

- Bootstrapped Routeprint from a fresh Rails scaffold.
- Started adapting the Wild Waters harness for Routeprint.
- Added initial Routeprint documentation, ADRs, PostGIS migration, and empty
  Inertia React shell.
- Expanded README and harness documentation from the Wild Waters control plane,
  adapted Routeprint source maps, security guidance, frontend design workflow,
  and project-local skills links.
- Added compact-output tooling regression coverage, Routeprint frontend test
  helpers, and a fuller map/geospatial ADR.
- Added ADR metadata headers, a linked ADR index, and README SDD Level 0-3
  guidance.
- Added project skill-routing guidance, compact OpenSpec skill adapters,
  lazy-loaded OpenSpec workflow references, and tooling regression coverage for
  the Routeprint agent harness.
- Added a compact `make agent-state` workspace snapshot and mechanical checks
  for sensitive logging filters and secret-like examples.
- Added the generated OpenSpec command delivery config under
  `config/openspec/config.json`.
- Started the authentication foundation change with ADR 0005 and OpenSpec
  artifacts for staged Wildwaters auth transfer.
