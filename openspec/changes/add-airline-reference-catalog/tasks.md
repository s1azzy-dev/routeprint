## 1. Architecture And Source Proof

- [ ] 1.1 Review proposed ADR 0009 against the implemented identity,
  designator, moderation, trusted-source, and unknown-airline boundaries; promote
  it to Accepted only when the implementation matches.
- [x] 1.2 Profile a bounded Wikidata airline export, freeze the source query and
  fixture, document CC0 attribution, and update the OpenSpec artifacts first if
  the available fields invalidate any confirmed assumption.

## 2. Persistence Red-Green Slice

- [x] 2.1 Add factories and red model/schema specs for airlines, designator
  assignments, submission audit, source links, review/operation independence,
  code collisions, optional dates/country, and merge-target integrity.
- [x] 2.2 Add the SQL-forward reversible migration with Routeprint UUID,
  timestamptz, foreign-key, required-column, within-airline designator
  uniqueness, pending-fingerprint, and lookup index boundaries.
- [x] 2.3 Implement the Airline, AirlineDesignator, submission-audit, and import
  link models with application-level normalization and lifecycle validation;
  run the narrow model specs until green and generate schema through the
  documented Make/container path.

## 3. Protected Unknown Airline

- [x] 3.1 Add red interactor/model specs proving idempotent creation and
  rejection of ordinary edit, moderation, merge, delete, and import mutation
  for `unknown_airline`.
- [x] 3.2 Implement the idempotent bootstrap and stable-key resolver used by
  future flight interactors; verify it without a hard-coded database UUID
  default.

## 4. Wikidata Import

- [x] 4.1 Add red fixture-backed import specs for QID source identity, valid
  automatic publication, unknown/closed records, missing optional evidence,
  ambiguous code/name candidates, malformed rows, and country-resolution
  diagnostics.
- [x] 4.2 Register the `wikidata_airlines` source and implement bounded
  QID-cursor acquisition, parsing, normalization, QID source-record/link
  persistence, and fail-fast canonical apply through the existing Imports
  orchestration.
- [x] 4.3 Add red/green idempotency, changed-snapshot, duplicate-delivery,
  retry-successor, and full-snapshot missing-upstream reconciliation coverage.

## 5. Authenticated Catalog Selection

- [x] 5.1 Add red request/query specs for authenticated bounded search by name
  and both designator systems, candidate collisions, approved-before-pending
  ordering, historical date ranking, closed-airline selection, and exclusion of
  rejected/merged/system rows.
- [x] 5.2 Implement the indexed airline lookup and allowlisted picker presenter
  with one preferred code, country display, and exceptional inactive/pending
  labels but no submission/import/review evidence.
- [x] 5.3 Add red interactor/request specs for explicit pending submission,
  name-only input, code-system inference, malformed input, exact pending reuse,
  legitimate shared-code confirmation, and submitter audit.
- [x] 5.4 Implement the pending-submission interactor and authenticated
  endpoint/component flow using standard shadcn selection/form primitives and
  bilingual copy.

## 6. Admin Airline Moderation

- [ ] 6.1 Add admin policy/request specs for member/guest denial, bounded
  pending history, safe audit props, valid/invalid correction, approval,
  rejection, merge-target validation, transactional merge rollback, and system
  airline protection.
- [ ] 6.2 Implement focused `yabi` moderation interactors for edit, approve,
  reject, and merge with reviewer/time evidence and fail-fast transactions.
- [ ] 6.3 Add the admin moderation routes, controller/presenter, paginated
  shadcn table, edit/review actions, empty state, confirmation behavior, and
  request/component/system coverage.

## 7. Admin Airline Import Operations

- [ ] 7.1 Add red request/component specs for protected Airlines import
  navigation, bounded safe history, guarded start, missing/disabled source, and
  concurrent-run rejection.
- [ ] 7.2 Extend the existing admin Imports shell with the Airlines history page
  and server-defined start action through the existing orchestration boundary.

## 8. Documentation And Verification

- [ ] 8.1 Update `CHANGES.md`, the README runtime foundation, ADR index,
  `docs/FOUNDATIONS.md`, and task/context ownership only where the implemented
  catalog changes the current source of truth.
- [ ] 8.2 Run `bin/openspec validate --all --strict`, the focused model,
  interactor, import, request, policy, frontend, and system specs, then
  `make verify-fast`.
- [ ] 8.3 Run `make verify`, review the implementation against every scenario,
  resolve mismatches, and only then archive the completed change and synchronize
  runtime/TODO documentation under the completion checklist.
