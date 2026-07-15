## 1. Admin HTTP contract and authorization

- [x] 1.1 Add failing request coverage for the admin airport-import index,
  pagination, navigation props, safe row fields, and admin/member/guest access.
- [x] 1.2 Add failing request coverage for starting an import, recording the
  current admin as initiator, success feedback, active-run rejection, and
  missing/disabled-source rejection.
- [x] 1.3 Add the nested admin imports routes, controller, server-side props,
  Pagy scope, fixed OurAirports start input, and translated flash handling.

## 2. Admin navigation and frontend page

- [x] 2.1 Extend the shared admin navigation contract with an Imports section
  and Airports item while preserving existing airport navigation behavior.
- [x] 2.2 Add the typed `Admin/Imports/Airports/Index` Inertia page with a
  shadcn table, status badges, progress counters, parameter summary, empty
  state, pagination, and start button.
- [x] 2.3 Add English/Russian copy and frontend tests for navigation, table
  rendering, start interaction, empty state, and accessibility semantics.

## 3. Verification and synchronization

- [x] 3.1 Run focused request and frontend specs; fix regressions in existing
  admin airport coverage.
- [x] 3.2 Update `CHANGES.md`, README runtime status, and `docs/TODO.md` if the
  current runtime/deferred-work entries mention this now-completed slice.
- [x] 3.3 Run strict OpenSpec validation, the relevant security/tooling checks,
  and the applicable `make verify` gate; verify the change against every
  requirement before archive.
