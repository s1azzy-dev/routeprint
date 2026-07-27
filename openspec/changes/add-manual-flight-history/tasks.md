## 1. Required Discovery Before Implementation

- [ ] 1.1 Re-enter OpenSpec Explore and confirm the minimum manual-entry fields,
  partial historical date/time behavior, timezone-resolution failures,
  duplicate candidates, list pagination/order, edit/delete UX, route-distance
  scope, and bilingual validation copy.
- [ ] 1.2 Update proposal, design, and `manual-flight-history` requirements with
  the confirmed behavior; remove every discovery-incomplete warning and open
  question only after user review.
- [ ] 1.3 Re-run `bin/openspec validate --all --strict` and obtain explicit
  approval of the completed artifacts before application, migration, or test
  implementation begins.

## 2. Persistence And Ownership Red-Green Slice

- [ ] 2.1 After discovery approval, add red factories/model/schema specs for the
  owned TravelSegment root, one-to-one FlightDetail specialization, airport
  route, ADR 0006 schedule evidence, required marketing airline, optional
  operating airline, and historical designator snapshot.
- [ ] 2.2 Add the reversible SQL-forward migration and models with explicit
  ownership, airport, airline, schedule, foreign-key, required-column, and
  list-query index boundaries; generate schema through the documented
  Make/container path.

## 3. Authorized Manual Flight Use Cases

- [ ] 3.1 Add red policy/interactor/request specs for create, list, show, update,
  and delete across owner, non-owner, member, and guest cases.
- [ ] 3.2 Implement one explicit `yabi` interactor per manual-flight action,
  including server-owned user assignment and `unknown_airline` resolution when
  selection is empty.
- [ ] 3.3 Add merge/rejection integration coverage proving flight relinking,
  preserved marketing-designator evidence, rejected-reference survival, and
  required replacement on later edit.

## 4. Manual Flight Interface

- [ ] 4.1 Add red request/component/system specs for the approved manual-entry
  fields, airline picker with approved/pending/unknown choices, validation,
  private bounded history, edit, and deliberate delete.
- [ ] 4.2 Implement the Inertia pages with standard shadcn components,
  page-specific props, explicit authorization, bilingual copy, and no raw
  import or policy evidence.

## 5. Documentation And Verification

- [ ] 5.1 Update `CHANGES.md`, README runtime status, `docs/TODO.md`, and
  `docs/CONTEXT_MAP.md` only after the manual-flight behavior is implemented.
- [ ] 5.2 Run strict OpenSpec validation, focused model/interactor/policy/request
  and frontend/system specs, then `make verify-fast`.
- [ ] 5.3 Run `make verify`, perform the OpenSpec implementation review, and
  archive only after every finalized requirement is proved.
