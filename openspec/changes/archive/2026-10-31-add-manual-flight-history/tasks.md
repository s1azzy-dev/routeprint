## 1. Artifact Review Gate

- [x] 1.1 Capture confirmed date/time, duplicate, and form decisions in the
  existing change; provide proposal, design, specs, and this ordered task list.
- [x] 1.2 Obtain explicit review approval of the completed artifacts, including
  proposed completion defaults and validation bounds; run
  `bin/openspec validate --all --strict` before implementation starts.

## 2. Flight Persistence And Schedule Resolution

- [x] 2.1 Write failing model/schema specs for owned TravelSegment/FlightDetail,
  independent dates, optional schedule evidence, carrier roles, reference
  deletion protection, and atomic rollback; confirm expected red results with
  `make agent-rspec SPEC='spec/models/travel_segment_spec.rb spec/models/flight_detail_spec.rb'`.
- [x] 2.2 Add explicit reversible SQL-forward migration/models and factories;
  generate structure.sql through Rails; prove 2.1 green against PostgreSQL,
  unique segment/detail and submission-key constraints, and protected references.
- [x] 2.3 Red/green the ADR 0006 resolver and persistence integration in focused
  resolver/interactor specs: date-only, missing arrival, DST gap/overlap,
  missing zone, overnight/date-line, chronology, and unrelated-edit snapshots.
- [x] 2.4 Record the implemented persistence/schedule slice in CHANGES.md and
  relevant runtime/context ownership docs; run `git diff --check`.

## 3. Selection And Authorized Writes

- [x] 3.1 Red/green bounded authenticated airport lookup with
  `spec/requests/airports_spec.rb` and focused query specs: code/name/localized
  matching, closed records, collisions, limits, safe payload, and indexes.
- [x] 3.2 Red/green explicit owner policies and create/read/list/update/delete
  interactors with policy/interactor/request specs for owner/non-owner/guest/admin;
  verify unknown carrier, optional operator, number bounds, fail-fast failures,
  retained inputs, and transactional rollback through focused `make agent-rspec`.
- [x] 3.3 Red/green candidate warnings and creation replay/race behavior with
  real PostgreSQL interactor/request specs; prove confirmation, edit exclusion,
  changed-input conflict, stable form identity, and cross-user isolation.
- [x] 3.4 Red/green carrier-state integration in focused flight specs: rejection
  survival, edit replacement, both-role relinking, snapshot preservation, and
  invalid-target/transaction rollback. Keep moderation endpoints/UI in the
  airline change; document its flight-side integration contract.
- [x] 3.5 Prove existing admin airport deletion cannot remove a referenced
  airport with focused admin request specs; document implemented lifecycle and
  lookup behavior in CHANGES.md/runtime/context sources and check the diff.

## 4. Manual Flight Interface

- [x] 4.1 Add failing request/component specs for bounded history, saved detail,
  shared create/edit form, airport/airline pickers, unknown/pending carriers,
  Additional details, duplicate confirmation, field errors, ru/en feedback,
  preserved values, accessible keyboard flow, and deliberate deletion.
- [x] 4.2 Implement Rails/Inertia endpoints, allowlisted typed props and
  feature-local shadcn form/history/detail components until 4.1 passes; run
  focused `make agent-rspec` and `make agent-frontend-test` plus format/type checks.
- [x] 4.3 Add/run system coverage for date-only create, detailed create,
  duplicate confirmation, edit, delete/cancel, and isolation; perform browser
  smoke of both locales, responsive layout, timezone warning, and keyboard use.
- [x] 4.4 Synchronize CHANGES.md, README runtime status, docs/TODO.md and
  docs/CONTEXT_MAP.md with implemented behavior; verify links and diff scope.

## 5. Integration And Completion

- [x] 5.1 Run `bin/openspec validate --all --strict`, focused integrated
  model/resolver/interactor/policy/request/component/system specs, and
  `make agent-verify-fast`; resolve failures and record actual evidence.
- [x] 5.2 Run canonical `make verify-fast`, `make security`, and `make verify`;
  verify critical flow coverage and safe payload boundaries; perform the
  OpenSpec implementation review and resolve scenario mismatches before archive.

## Workflow follow-up

- Archive only after verification and review pass; synchronize the new baseline
  capability with README/TODO/CHANGES/context completion rules in the same change.
- Do not archive/promote the unfinished country or airline change as a side effect.
- Publishing/PR requires separate authorization; never push main.

## Verification Evidence

- Red/green: model/schema, resolver, owned use cases, duplicate/replay and real
  concurrent creation, HTTP policies, nested validation errors, bounded display
  queries, keyboard selection, and visible pending-carrier regression cases.
- Final canonical proof: `make verify` passed on Rack 3.2.8 (490 RSpec examples;
  42 frontend tests; format/lint/types/build, OpenSpec, audit and security gates).
  This includes `make verify-fast` and `make security`.
- Ruby coverage: 95.08% globally; flight backend files 98.15%. Vitest reports
  58.57% global frontend line coverage including existing shared UI primitives;
  its configured gate has no percentage threshold.
- `make agent-verify-fast` initially found test fixture residue; the concurrency
  test now uses a dedicated approved carrier and cleans up its own records.
  The subsequent canonical full suite passed without that residue.
- Browser: date-only create, duplicate warning/confirmation, edit, DST uncertainty,
  cancel/confirm delete, ru/en, 390px mobile layout, and keyboard airport selection
  verified. Console had no relevant errors. Temporary QA records were removed.
- npm audit retains 19 low/moderate advisories (2 low, 17 moderate) in the existing
  dependency graph; none meet the configured high-severity failure threshold.
- Final security gate exposed Rack 3.2.7 advisories; the only lockfile change is
  the conservative 3.2.8 patch. Bundler audit and Brakeman passed afterward.
- At implementation handoff, no dependencies were added, no CI or production
  deployment was performed, and publishing had not yet been requested.
