## 1. Specification and authorization

- [x] 1.1 Add admin airport routes, `Admin::BaseController`, and server-side admin navigation props.
- [x] 1.2 Add `Admin::AirportPolicy` plus request/policy coverage for guest, member, and admin boundaries.
- [x] 1.3 Add the `Admin::UpdateAirport` contract/interactor and focused interactor coverage for atomic success and validation failure.

## 2. Admin airport backend

- [x] 2.1 Implement paginated airport index props with stable ordering, bounded rows, and safe delete failure feedback.
- [x] 2.2 Implement update and delete request flows with redirect/validation contracts and provenance-preserving behavior.
- [x] 2.3 Add English and Russian admin copy and update `CHANGES.md`.

## 3. Frontend workspace

- [x] 3.1 Add the admin-only account menu item and current-area handoff in the Routeprint shell.
- [x] 3.2 Add the Wild Waters-inspired admin layout with left navigation and central workspace.
- [x] 3.3 Add the airport table, pagination, edit form, validation states, and delete confirmation using existing shadcn primitives.
- [x] 3.4 Add component tests for admin navigation, airport rows, update form behavior, delete confirmation, and empty/pagination states.

## 4. Verification

- [x] 4.1 Run narrow policy, interactor, request, and frontend tests.
- [x] 4.2 Run `bin/openspec validate --all --strict`, `make agent-verify-fast`, and the applicable security gate.
- [x] 4.3 Run `make verify` before handoff and verify no generated schema file was edited by hand.
