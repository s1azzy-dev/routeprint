## 1. Stage 0: Architecture And Specification

- [x] 1.1 Add ADR 0005 for the Routeprint authentication foundation decision.
- [x] 1.2 Update the ADR index and `CHANGES.md`.
- [x] 1.3 Validate the OpenSpec change before implementation.

## 2. Stage 1: Core Schema And Models

- [x] 2.1 Inspect the Wildwaters auth model, constants, current-attributes, normalizer, factory, and model-spec files selected by the transfer plan.
- [x] 2.2 Add failing model/lib specs for `User`, `UserIdentity`, `UserSession`, `Current`, and `EmailNormalizer`.
- [x] 2.3 Add migrations for `users`, `user_identities`, and `user_sessions` using Routeprint database conventions.
- [x] 2.4 Adapt Wildwaters model behavior to Routeprint, including `Session` to `UserSession`, token digests, reset TTL, role/status helpers, and password minimum length 12.
- [x] 2.5 Run the targeted model/lib specs, then the selected fast verification gate.

## 3. Stage 2: Registration, Login, Logout, And Current Session

- [x] 3.1 Inspect the Wildwaters authentication concern, sessions/registrations controllers, auth interactors, routes, request specs, and matching frontend auth components.
- [x] 3.2 Add failing request/interactor/frontend specs for registration, login, logout, protected dashboard, cookie behavior, suspended users, and `last_seen_at` throttling.
- [x] 3.3 Implement the authentication concern, registration/login/logout interactors, controllers, routes, signed `:user_session_token` cookie, and minimal protected dashboard.
- [x] 3.4 Implement minimal Routeprint Inertia auth/dashboard pages without expanding the design system unnecessarily.
- [x] 3.5 Run the targeted auth request/interactor/frontend specs, then `make verify-fast` and `make security`.

## 4. Stage 3: Password Reset

- [ ] 4.1 Inspect the Wildwaters password reset controller, interactors, mailer, mail templates, routes, and specs.
- [ ] 4.2 Add failing request/interactor/mailer specs for generic reset responses, digest-backed tokens, expiry, invalid tokens, password policy, and session revocation.
- [ ] 4.3 Implement password reset request and consume flows with transient raw tokens, stored digests, 30-minute TTL, generic responses, and all-session revocation.
- [ ] 4.4 Run the targeted reset and mailer specs, then `make verify-fast` and `make security`.

## 5. Stage 4: Security Notes And Deferred Boundaries

- [ ] 5.1 Add or update the owning security/TODO documentation for cookie policy, token storage, suspended users, identity versus connected account boundary, deferred rate limiting, deferred email verification, deferred OAuth, and deferred connected accounts.
- [ ] 5.2 Add or strengthen specs for no raw token persistence, no auth tokens in Inertia props, generic auth/reset errors, suspended-session rejection, and reset session revocation.
- [ ] 5.3 Confirm that no OAuth, connected-account token storage, public API, native mobile, live tracking, AI, or import/sync behavior was introduced.

## 6. Final Verification And Archive

- [ ] 6.1 Run `bin/openspec validate add-auth-foundation --strict` and `make verify`.
- [ ] 6.2 Update implementation notes if verification discovers a required spec/design correction.
- [ ] 6.3 Archive the OpenSpec change after implementation and verification are complete.
