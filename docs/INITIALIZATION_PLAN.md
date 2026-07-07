# Routeprint Initialization Plan

This document owns the bootstrap plan up to the first business task. The target
state is a clean Routeprint Rails/PostGIS monolith with the Wild Waters-level
harness adapted to Routeprint, a working empty Inertia React page, and passing
verification gates.

## Task Packet

```text
Task: Bootstrap Routeprint before first business task.
Task type: Architecture/tooling/project bootstrap
SDD level: 3
OpenSpec change: create bootstrap/foundation artifacts during initialization
ADR: required for frontend, map/geospatial, import architecture, and UI foundation
Behavior change: yes, new project foundation
Risk class: high
Reference project: /Users/a.tselovalnikov/projects/wildwaters
Runtime command environment: Make/Docker first; host only for git, search, editing, Docker orchestration, and documented wrappers
Red test required: not before generated app bootstrap; required before first business behavior
Approval required: before adding dependencies outside the approved stack or changing architecture
Final verification: make doctor, make openspec-validate, make frontend-verify, make security, make verify-fast, make verify
Done condition: empty Routeprint app boots in Docker, renders an Inertia React page, all plan items are complete or documented with exact blockers, and no Wild Waters business/domain references remain
```

## Bootstrap Strategy

Use `rails new` as the base generator, then copy/adapt Wild Waters harness files.
This keeps Rails internals coherent while preserving the reference project's
process, verification, Docker, frontend, and agent-control layers.

Do not copy Wild Waters business logic. Reuse patterns and harness only.

## Phase 0: Reference Inventory

- [x] Confirm Routeprint checkout is clean enough for bootstrap.
- [x] Inspect current Wild Waters `main` or local reference state.
- [x] Record the exact Rails, Ruby, Node, gem, npm, Docker, and OpenSpec versions
      being copied or generated.
- [x] Inventory Wild Waters harness files:
      `AGENTS.md`, `.codex/`, `.agents/`, `.devcontainer/`, `.githooks/`,
      `.github/`, Dockerfiles, `docker-compose.yml`, `Makefile`, bin wrappers,
      frontend config, RSpec config, RuboCop config, OpenSpec config, docs, ADRs.
- [x] Inventory Wild Waters runtime foundations:
      Rails, PostgreSQL/PostGIS, Inertia Rails, React, TypeScript, Vite,
      Tailwind, shadcn/ui, RSpec, Vitest, Pundit, Active Storage, Solid Queue,
      Solid Cache, Mission Control Jobs, RTK-backed agent targets.
- [x] Inventory Wild Waters domain code that must not be copied:
      waterfalls, spots, regions, GeoNames, waterfall map payloads, waterfall UI,
      waterfall specs, product copy, locale copy, and nature design language.

## Phase 1: Generate Rails Baseline

- [x] Generate a fresh Rails app in the current folder with PostgreSQL support
      and without committing generated noise prematurely.
- [x] Keep `structure.sql` as the intended schema format.
- [x] Configure app name, module names, database names, Docker service names, and
      package name as Routeprint.
- [x] Add PostGIS as a first-class database dependency.
- [x] Verify the generated baseline boots far enough to accept harness wiring, or
      document the exact generator/runtime blocker.

## Phase 2: Transfer Harness

Copy or adapt these layers from Wild Waters:

- [x] Agent control plane:
      `AGENTS.md`, `.codex/`, `.agents/skills/`, RTK config, harness regression
      expectations.
- [x] Workflow docs:
      `docs/CONTEXT_MAP.md`, `docs/DEVELOPMENT.md`, `docs/QUALITY_SECURITY.md`,
      `docs/TODO.md`, ADR index.
- [x] OpenSpec:
      `openspec/config.yaml`, wrappers, validation targets, initial foundation
      structure.
- [x] Docker/devcontainer:
      Dockerfiles, compose file, devcontainer, entrypoints, env examples.
- [x] Makefile:
      setup, doctor, up/down/logs, bundle, frontend gates, test, security,
      verify-fast, verify, RTK-backed agent targets, outdated checks.
- [x] CI and repository hygiene:
      GitHub workflow, Dependabot, CODEOWNERS if useful, PR template, hooks,
      editor/prettier/rubocop/rspec/gitignore/gitattributes config.
- [x] Backend quality stack:
      RSpec, SimpleCov, FactoryBot, Faker, Shoulda Matchers, RuboCop, Brakeman,
      bundler-audit.
- [x] Frontend stack:
      Vite Rails, Inertia React, TypeScript strict config, Vitest, React Testing
      Library, ESLint, Prettier, Tailwind, shadcn/ui, lucide.
- [x] Rails app foundations:
      session/auth scaffolding only if needed for the empty protected shell;
      otherwise defer auth behavior to the first business foundation task.

## Phase 3: Adapt To Routeprint

- [x] Replace names:
      `Wild Waters`, `wildwaters`, `WW_`, waterfall, spot, region, GeoNames,
      and product-specific identifiers.
- [x] Rewrite `AGENTS.md` as a short Routeprint control plane.
- [x] Rewrite `docs/FOUNDATIONS.md` for Routeprint:
      personal travel history, flight-first MVP, private by default, Routeprint
      domain areas, imports, map, PostGIS boundaries.
- [x] Rewrite `docs/CONTEXT_MAP.md` for Routeprint paths:
      auth, airports, airlines, travel segments, flight details, imports, map,
      stats, exports, admin, frontend tooling.
- [x] Rewrite `docs/DEVELOPMENT.md` for Routeprint:
      SDD levels, command contract, permission matrix, verification matrix,
      RTK-backed commands, no raw host Rails/npm runtime work.
- [x] Rewrite `docs/QUALITY_SECURITY.md` for travel-data privacy:
      exact travel history, future trips, raw imports, booking references, seats,
      boarding passes, timestamps, private uploads.
- [x] Create Routeprint ADRs:
      `0001-map-and-geospatial-stack.md`,
      `0002-business-frontend-architecture.md`,
      `0003-import-architecture.md`,
      `0004-ui-component-foundation.md`.
- [x] Create Routeprint `docs/TODO.md` from the MVP sequence:
      bootstrap, auth, airports/airlines, manual flights, map, CSV import,
      App in the Air import, export, launch.
- [x] Update `README.md` and `CHANGES.md`.
- [x] Keep OpenSpec baseline honest:
      no fictional implemented business specs; create only bootstrap/foundation
      specs that match working behavior.

## Phase 4: Empty App Runtime

- [x] Configure a minimal Rails route for the empty app shell.
- [x] Configure Inertia layout and React entrypoint.
- [x] Render a minimal Routeprint React page.
- [x] Ensure frontend assets resolve through Vite in development, test, and
      production build modes.
- [x] Ensure Tailwind and shadcn foundations compile.
- [x] Ensure TypeScript strict checks pass.
- [x] Keep page props least-data and non-sensitive.
- [x] Do not implement flight, airport, import, map, stats, export, auth, or
      admin product behavior unless explicitly needed for bootstrap.

## Phase 5: Database And PostGIS Foundation

- [x] Configure PostgreSQL test/development databases as Routeprint databases.
- [x] Enable PostGIS through Rails migrations, not manual schema edits.
- [x] Verify PostGIS version and extension availability in the container.
- [x] Establish spatial conventions for future work:
      WGS84 storage, explicit SRID, spatial indexes when spatial columns arrive,
      real database tests for geospatial behavior.
- [x] Do not create flight-domain tables before the first business task unless a
      bootstrap check strictly requires a placeholder.

## Phase 6: Verification And Cleanup

- [x] Run `git diff --check`.
- [x] Run `make doctor`.
- [x] Run `make openspec-validate`.
- [x] Run `make frontend-verify`.
- [x] Run `make security`.
- [x] Run `make verify-fast`.
- [x] Run `make verify`.
- [x] Search for forbidden leftovers:
      `Wild Waters`, `wildwaters`, `waterfall`, `spot`, `region`, `geonames`,
      `WW_`, copied nature/water design copy.
- [x] For any remaining reference, either remove it or document why it is an
      intentional migration/reference note.
- [x] Confirm no secrets or local credentials are committed.
- [x] Confirm `db/structure.sql` is generated only by Rails tasks.

## Success Criteria

Initialization is complete when:

- [x] Routeprint is named consistently across Rails, Docker, npm, databases, CI,
      docs, OpenSpec, and agent harness.
- [x] `make setup` can build/start the stack, or the exact local blocker is
      documented.
- [x] The app serves a minimal Inertia React Routeprint page.
- [x] Backend, frontend, TypeScript, Tailwind, shadcn, Docker, PostGIS, RSpec,
      Vitest, security, OpenSpec, and RTK-backed Make targets are initialized.
- [x] Important Wild Waters documents and harness patterns are present and
      adapted.
- [x] No Wild Waters business logic or product-specific UI/domain behavior has
      been copied.
- [x] Full verification passes, or every remaining failure is exact,
      reproducible, and environment-scoped.
- [x] The repository is ready for the first business task through SDD/OpenSpec.

## Completion Evidence

Completed on 2026-07-07.

- Rails scaffold generated with Rails 8.1.3 from the Wild Waters container
  bundle.
- Ruby is pinned to 4.0.5 and Node to 24.18.0 in project/container tooling.
- PostgreSQL/PostGIS runs through Docker Compose with host port `5433`.
- Rails serves on host port `3001`; Vite dev server is mapped to `3038`.
- Root page renders the `Home/Show` Inertia React component with Routeprint-only
  bootstrap props.
- Wild Waters business/domain code was not copied.
- Domain leftovers search is clean outside intentional bootstrap-reference notes.
- Verification passed:
  `git diff --check`,
  `make doctor`,
  `make openspec-validate`,
  `make frontend-verify`,
  `make security`,
  `make verify-fast`,
  `make verify`.
