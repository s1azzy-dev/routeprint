# Context Map

This document owns task-specific context loading for Codex. Its job is to help
the agent read the smallest useful file set before acting.

Use it after classifying the task with `docs/DEVELOPMENT.md`. Do not use it as a
substitute for inspecting neighboring files; local examples still win.

## Loading Rules

- Start from the relevant row below, not from a repository-wide scan.
- Read listed source-of-truth files first, then the directly relevant app/spec
  files, then neighboring examples.
- Prefer `rg` and targeted file reads over broad directory dumps.
- Read generated artifacts only when the task depends on their generated
  output.
- For Level 2 or 3 work, inspect related active changes before creating a new
  change and read current capability specs before changing existing behavior.
- Treat ADRs as implemented architecture decisions, not feature specifications.
- Use `docs/TODO.md` only when selecting or scoping unimplemented work.
- If a source still conflicts with established code and RSpec, treat the
  implementation as evidence and repair the owning document.
- If the mapped context is insufficient, expand one directory or pattern at a
  time and record what was added in the task packet.

## General Orientation

Read for broad orientation only when starting a new session, changing project
rules, or making cross-cutting decisions.

| Need | Read |
| --- | --- |
| Agent operating rules | `AGENTS.md`, `docs/DEVELOPMENT.md` |
| Product/domain/database boundaries | `docs/FOUNDATIONS.md` |
| Security/testing/merge gates | `docs/QUALITY_SECURITY.md` |
| Spec-driven task levels and lifecycle | `docs/DEVELOPMENT.md` |
| Token-efficient agent commands | `docs/DEVELOPMENT.md`, `Makefile` |
| Current capability behavior | `openspec/specs/` |
| Active feature changes | `openspec/changes/`, `bin/openspec list --json` |
| Prioritized unimplemented work | `docs/TODO.md` |
| Human project entrypoint | `README.md` |
| Durable architecture decisions | `docs/adr/README.md`, then the specific ADR |
| Recent project changes | `CHANGES.md` |
| Codex eval harness | `harness/README.md`, `harness/evals/cases.yml`, `bin/harness-eval`, `bin/harness-run` |
| Commands | `Makefile` |
| Dependencies | `Gemfile`, `Gemfile.lock`, `package.json`, `package-lock.json` |
| Routes and entrypoints | `config/routes.rb` |

## Project Skill Routing

Use project-local skills before broad global skills when they cover the same
workflow. Load only the routed skill plus the rows named by this map.

| Trigger | Skill | Read first | Verification |
| --- | --- | --- | --- |
| Any Routeprint repository task | `$routeprint-sdd-intake-gate` | `AGENTS.md`, SDD/command/permission/verification sections of `docs/DEVELOPMENT.md`, relevant row here | Gate-selected check |
| Feature discovery, OpenSpec, or ADR decision | `$routeprint-spec-driven-change` | Relevant capability spec, active changes, selected app/spec slice | `bin/openspec validate --all --strict` plus project gate |
| Resume, publish, review, or orient branch state | `$routeprint-workspace-state` | Git status, branch, last commit, compact diff names when needed | Reuse or rerun gate by freshness |
| Auth, sessions, admin, uploads, privacy, or user-owned data | `$routeprint-authz-security-flow` | `docs/QUALITY_SECURITY.md`, active route/controller/policy/spec slice | Narrow security specs, then `make security` when required |
| Airports, routes, map payloads, PostGIS, or geospatial performance | `$routeprint-postgis-map-query` | `docs/FOUNDATIONS.md`, geospatial ADR when behavior changes, target query/model/spec | Narrow spec, then `make verify-fast` |
| Business use case or `app/interactors` change | `$routeprint-yabi-interactor` | `app/interactors/application_interactor.rb`, target interactor/spec, one good neighbor | Narrow interactor/request spec; conventions tooling spec when style rules change; then selected gate |

## Backend Context

| Task area | Start with | Then inspect |
| --- | --- | --- |
| Auth/session/password reset | `docs/QUALITY_SECURITY.md`, `config/routes.rb` | Once present: authentication concern, sessions/registrations/password-reset controllers, auth interactors, user/session models, matching request/interactor/model specs |
| Admin/authorization | `docs/QUALITY_SECURITY.md`, `app/policies/application_policy.rb` | Once present: admin base controller, matching controller/request/policy specs, and neighboring admin flows |
| Places/airports | `docs/FOUNDATIONS.md`, `docs/adr/0001-map-and-geospatial-stack.md`, `docs/adr/0006-time-zone-and-flight-schedule-time-handling.md` | Once present: place/airport models, airport factories, airport search/import specs, relevant migrations |
| Airlines | `docs/FOUNDATIONS.md` | Once present: airline model, airline factories/import specs, relevant migrations |
| Travel segments/flights | `docs/FOUNDATIONS.md`, `docs/adr/0006-time-zone-and-flight-schedule-time-handling.md`, `config/routes.rb` | Once present: travel segment and flight detail models, flight interactors/queries/presenters, request/system/interactor specs |
| Imports/App in the Air/CSV | `docs/FOUNDATIONS.md`, `docs/adr/0003-import-architecture.md`, `docs/QUALITY_SECURITY.md` | Once present: import models, import interactors/jobs, parser fixtures, import specs |
| Models/domain persistence | Relevant model and matching factory/spec | Neighboring models, relevant migrations, related interactors |
| Interactors/use cases | `app/interactors/application_interactor.rb`, relevant interactor | Matching interactor spec, neighboring interactor in same namespace, relevant contract/model |
| Queries/presenters | Relevant query/presenter | Matching spec, controller/view caller, neighboring query/presenter |
| Jobs/mailers | Relevant job/mailer | Matching specs, queue config, templates for mailers |
| Configuration | `config/configs/`, `config/initializers/01_settings.rb` | Matching config specs, environment files only when needed |
| Migrations/schema | Recent migrations in `db/migrate/`, `docs/FOUNDATIONS.md` | Relevant model/spec; `db/structure.sql` only for generated output inspection |

## Frontend Context

| Task area | Start with | Then inspect |
| --- | --- | --- |
| Frontend architecture or runtime boundary | `docs/adr/0002-business-frontend-architecture.md`, relevant OpenSpec capability/change | `app/frontend/`, `app/views/layouts/inertia.html.erb`, matching request/component/system specs |
| Frontend UI kit or design workflow | `docs/adr/0004-ui-component-foundation.md`, `docs/frontend/DESIGN_GUIDE.md`, relevant OpenSpec capability/change | `app/frontend/components/ui/`, `app/frontend/components/routeprint/`, relevant page/component tests |
| Inertia page or layout | `app/views/layouts/inertia.html.erb`, relevant page in `app/frontend/pages/` | Rails controller/request spec, page prop types, React Testing Library test, routing/system coverage |
| Auth screens | Relevant page in `app/frontend/pages/Sessions/`, `app/frontend/pages/Registrations/`, or `app/frontend/pages/PasswordResets/` | Auth controller/request specs, React page tests, locale files |
| Flight pages | Relevant page in `app/frontend/pages/Flights/` once present | Flight controller, flight presenter/query, request/system specs |
| Travel map UI | Relevant page in `app/frontend/pages/Map/` and MapLibre helper once present | Map/GeoJSON controller, MapLibre ADR, map system/request specs, local MapLibre assets |
| UI components | `docs/frontend/DESIGN_GUIDE.md`, relevant `app/frontend/components/*` TypeScript files | Matching React component/page tests, neighboring component APIs, ADR 0002 and ADR 0004 when shared patterns change |
| Styles/design tokens | `app/frontend/styles/design_tokens.css`, `app/frontend/entrypoints/application.css`, `docs/frontend/DESIGN_GUIDE.md` | Relevant React page/component, component/system specs, production Vite manifest |
| Frontend tooling | `package.json`, `vite.config.ts`, `config/vite.json`, `eslint.config.mjs`, `tsconfig.json` | `spec/tooling/frontend_foundation_configuration_spec.rb`, `Makefile`, CI and Docker build files |
| I18n copy | `config/locales/en.yml`, `config/locales/ru.yml` | UI code using the keys, request/system coverage when behavior changes |

## Test Context

| Test need | Read |
| --- | --- |
| Test framework setup | `spec/rails_helper.rb`, `spec/spec_helper.rb` |
| Factory style | Relevant `spec/factories/*`, neighboring factory |
| Request specs | Relevant file in `spec/requests/`, neighboring request spec |
| System specs | Relevant file in `spec/system/`, neighboring system spec |
| Interactor specs | Relevant file in `spec/interactors/`, neighboring namespace spec |
| Model specs | Relevant file in `spec/models/`, matching model/factory |
| Policy specs | `spec/support/pundit.rb`, relevant file in `spec/policies/` |
| React component tests | Relevant file in `app/frontend/test/`, page/component source, `app/frontend/test/setup.ts` |
| Job/mailer specs | Relevant file in `spec/jobs/` or `spec/mailers/` |
| Tooling/bin specs | Relevant file in `spec/bin/`, `spec/tooling/`, or `spec/lib/` |
| External fixtures | Relevant file in `spec/fixtures/` only when the spec uses it |

## Source of Truth

| Subject | Source of truth |
| --- | --- |
| Agent operating contract | `AGENTS.md` |
| Context loading | `docs/CONTEXT_MAP.md` |
| Workflow, permissions, verification | `docs/DEVELOPMENT.md` |
| Product, architecture, domain, database boundaries | `docs/FOUNDATIONS.md` |
| Security/testing/risk gates | `docs/QUALITY_SECURITY.md` |
| Current feature intent and observable behavior | `openspec/specs/` |
| Proposed feature changes, design, and tasks | `openspec/changes/` |
| Known unimplemented work | `docs/TODO.md` |
| Durable architecture decisions | `docs/adr/` |
| Frontend design workflow | `docs/frontend/DESIGN_GUIDE.md` |
| Routes | `config/routes.rb` |
| Commands | `Makefile` |
| Dependencies | `Gemfile`, `Gemfile.lock`, `package.json`, `package-lock.json` |
| Runtime configuration shape | `config/database.yml`, environment variables, and relevant initializers |
| Database schema state | Rails migrations and generated `db/structure.sql` |
| Queue schema state | Queue migrations and generated `db/queue_structure.sql` |
| I18n copy | `config/locales/en.yml`, `config/locales/ru.yml` |
| UI component API | React component TypeScript file and matching frontend test |
| Current behavior | Relevant app code plus matching request/system/interactor/model spec |

## Updating This Map

Update `docs/CONTEXT_MAP.md` when:

- a new top-level app area, namespace, or repeated workflow is added;
- files are moved, renamed, or made canonical;
- a new ADR changes where agents should look first;
- a repeated Codex failure came from missing or excessive context;
- task routing in `docs/DEVELOPMENT.md` changes;
- README or source ownership changes affect human/agent entrypoints.

Update style:

- Prefer changing one row over adding broad instructions.
- Remove stale paths in the same edit that introduces new ones.
- Keep this file as an index, not a tutorial.
- Validate with `git diff --check` for docs-only updates.
