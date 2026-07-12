# Changes

## 2026-07-12

- Added Routeprint permission governance: stable Make allow targets, trimmed
  shell environment inheritance, dependency-approval grading, external-content
  policy, and a read-only reviewer profile.
- Added positive/negative trigger cases for Routeprint skills and shortened the
  SDD intake skill so clear Level 0–1 work stays on the Fast Path.
- Prefer compact `make agent-*` commands in agent-facing workflow guidance,
  while retaining ordinary Make targets for canonical final and CI proof.
- Added adaptive SDD routing: clear Level 0–1 work stays on the Fast Path,
  while intake and spec-driven skills activate for uncertainty, risk, Level 2–3
  scope, or compaction handoff; archive checks now cover context ownership and
  obsolete skill/rule cleanup.
- Added a compact context-engineering path, level-specific intake packets, and
  mechanical agent-harness checks wired into Make and CI; domain skills now keep
  only their workflow-specific guidance.
- Hardened the Codex eval harness after real runs: bounded ephemeral execution,
  untracked-file-aware grading, structured command exit evidence, workflow and
  behavior checks, human review records, smoke profiles, and source-stable
  experiment hashes now prevent false-positive and runaway benchmark results.
- Added a repository-specific Codex eval harness with 12 registered cases,
  disposable-worktree JSONL runs, mechanical safety/workflow graders, human
  rubrics, experiment metrics, and Markdown reporting; raw runs remain under
  ignored temporary paths.
- Added weekly Dependabot npm updates with minor/patch grouping; major updates
  remain separate for Context7 or official migration-guide review.
- Moved the project Codex allow-rule from raw Docker RSpec commands to stable
  Make verification targets; raw Docker commands remain outside the allowlist.

## 2026-07-11

- Separated RuboCop checking from explicit autocorrection: verification gates
  are now non-mutating, while `rubocop-fix` and `agent-rubocop-fix` perform
  autocorrection intentionally.
- Centralized frontend, Ruby, and RSpec verification in reusable Make targets;
  the regular and RTK-backed fast gates now share the same stage boundaries.
- Synchronized the roadmap with the implemented auth, password-reset,
  protected-dashboard, and airport-reference foundations; future OpenSpec
  archives now require the matching CHANGES, README, and TODO updates in one PR.

## 2026-07-10

- Defined the accepted admin reference-import subsystem architecture: durable
  source/run/item history, raw-artifact and source-record provenance, immutable
  retries, structured item failures, Solid Queue execution, and explicit
  source-to-airport mapping; user imports and admin UI remain separate work.
- Implemented the import foundation, durable item orchestration, private raw
  artifacts, source-record snapshots, structured item errors, and the first
  OurAirports airport adapter with conservative matching, WGS84 persistence,
  and full-snapshot missing-upstream reconciliation.
- Added the `csv` runtime gem required by Ruby 4 for provider CSV parsing.
- Simplified item execution: Solid Queue now limits one job per run item,
  claim is a queued-to-running status transition, and cancellation/lease
  orchestration is removed from this slice.
- Removed checkpoint persistence and resume semantics; retries now reprocess a
  complete item from the beginning.
- Reworked source processing into ordered acquire/parse/raw-persist/apply
  phases: raw rows commit first, canonical apply is transactional, and phase
  failures stop the item instead of continuing row-by-row. The normal recovery
  path is a new full run; the old row-issue interactor is no longer active.
- Added explicit input contracts to all application interactors and concise
  YARD documentation for interactors and public helper methods.
- Routed nested interactor calls through injected `option` dependencies so
  adapter and artifact orchestration remain replaceable in tests and runtime.
- Refined import orchestration interactors to use explicit monadic pipelines,
  narrow exception boundaries, and atomic claim/finalization flows without
  splitting already-simple use cases into unnecessary helpers.
- Promoted the import-refactor feedback into the Routeprint harness: explicit
  fail-fast interactor pipelines, orchestration-first `call`, real contracts,
  YARD, injected collaborators, complexity limits, realistic pipeline tests,
  and mechanical convention checks are now durable project rules.
- Fixed GitHub Actions PostGIS initialization so Rails loads `structure.sql` into a clean test database.
- Added the fixed-wing airport reference foundation with PostGIS points,
  localized `place_names` fallbacks, timezone verification metadata, optional
  IATA/ICAO lookup codes, and retained closed records for historical travel.
- Kept domain vocabularies, code formats, and timezone workflow rules in the
  application layer instead of encoding them as database `CHECK` constraints.
- Added ADR 0006 defining Routeprint's dual representation of airport-local
  schedule times and UTC instants, IANA timezone snapshots, conservative DST
  resolution, duration semantics, future-flight recalculation, historical
  provenance, and privacy boundaries.

## 2026-07-09

- Strengthened the frontend architecture and UI-kit guidance from the Wild
  Waters frontend workflow: Rails/Inertia boundaries, component ownership,
  shadcn-first composition, Routeprint wrapper layering, and frontend quality
  gates are now explicit in ADRs and the design guide.
- Added password reset request and consume flows with digest-backed reset
  tokens, generic reset responses, reset mailer templates, password-policy
  enforcement, all-session revocation after reset, and minimal Inertia reset
  pages.
- Hardened the auth foundation boundary so `UserIdentity` metadata rejects
  external token-like fields, security docs capture session cookie and token
  storage rules, and TODO tracks deferred rate limiting, email verification,
  OAuth, and connected accounts.

## 2026-07-08

- Added typed runtime configuration loading through `BootConfig` and
  `ApplicationConfig`, then routed database, Puma, Action Cable, mailer URL,
  storage, logging, CI, and queue settings through the config objects.
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
