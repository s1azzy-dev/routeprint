## Context

Routeprint currently has only the bootstrap application shell. The first
user-owned travel features require a reliable account boundary, but the MVP
does not need OAuth, external mailbox tokens, or public account-linking flows
yet. Wildwaters provides a known-good Rails auth foundation that can be ported
with Routeprint-specific naming and privacy constraints.

This is a Level 3 change. It creates ADR 0005 because the account/session model
and identity/integration boundary are durable architecture choices.

## Goals / Non-Goals

**Goals:**

- Port the Wildwaters password-auth foundation into Routeprint with Routeprint
  names, routes, and UI copy.
- Use `User`, `UserIdentity`, and `UserSession` as the core account/session
  persistence model.
- Keep raw session and password-reset tokens out of the database.
- Provide registration, login, logout, current-session resume, a minimal
  protected dashboard, and password reset.
- Enforce a minimum password length of 12 characters.
- Prevent suspended users from signing in or continuing existing sessions.
- Document the future boundary between login identities and external connected
  accounts.

**Non-Goals:**

- OAuth login.
- Gmail, Outlook, calendar, TripIt, or other connected-account import/sync.
- Mandatory email verification.
- Native mobile, public API, live tracking, AI, or offline-first auth flows.
- New gems, packages, external services, or token encryption infrastructure.
- User-owned travel resource routes beyond a minimal protected dashboard.

## Decisions

1. Use `UserSession`, not `Session`.

   Wildwaters uses a `Session` model shape. Routeprint will rename it to
   `UserSession` and use `Current.user_session` plus a `:user_session_token`
   cookie. This avoids ambiguity with Rails controller `session` and browser
   sessions. Keeping `Session` would reduce transfer churn, but the long-term
   naming cost is higher.

2. Keep login identity separate from connected accounts.

   `UserIdentity` represents a way to authenticate into Routeprint, such as
   password now and OAuth later. External import/sync integrations belong to a
   future `ConnectedAccount` model, not to `user_identities.metadata`. This
   keeps Gmail/Outlook/calendar tokens out of the auth identity table and makes
   consent, scope, encryption, disconnect, and sync state explicit later.

3. Implement password auth first.

   Password registration, login, logout, current-session resume, and password
   reset are enough to unlock private user-owned MVP features. OAuth account
   linking needs a separate policy decision and must not silently merge accounts
   by email.

4. Store only token digests.

   Session tokens and password-reset tokens are generated as transient raw
   values, digested with SHA-256 for lookup, and never persisted raw. Reset
   tokens remain time-bound and single-use.

5. Reserve email verification without enforcing it in the early MVP.

   The `users.primary_email_verified_at` and `user_identities.email_verified`
   shape keeps the schema compatible with verification, OAuth linking, and email
   import, but this change does not require verified email for login.

6. Keep auth UI minimal and Routeprint-owned.

   Auth screens and the protected dashboard use the existing Inertia React
   stack. They should not expand the design system unless a concrete auth
   control needs it.

7. Defer rate limiting unless the current stack already has an approved
   built-in path.

   Public auth endpoints require abuse protection, but adding a new dependency
   or broad throttling architecture is outside this change. If Rails-native
   limiting is not already available and accepted, document the deferral in
   `docs/TODO.md` or the auth security notes.

## Risks / Trade-offs

- Model rename transfer churn -> Keep the rename mechanical and covered by
  model/request specs before controller work.
- Account enumeration -> Use generic login and password-reset responses for
  sensitive failure paths.
- Stale sessions after suspension or reset -> Cover suspended resume and reset
  revocation in request/model specs.
- Cookie misconfiguration -> Assert signed cookie behavior and review cookie
  flags in security-focused specs.
- Future OAuth/email import confusion -> ADR 0005 and the auth security notes
  must state that `UserIdentity` is not a connected-account token store.
- Rate limiting deferral -> Record the missing control explicitly so it cannot
  be mistaken for implemented protection.

## Migration Plan

1. Add the ADR and OpenSpec artifacts.
2. Add core auth migrations, models, constants, normalizers, factories, and
   model specs.
3. Add registration, login, logout, current-session resume, protected dashboard,
   routes, controller concern, auth interactors, request specs, and minimal UI.
4. Add password reset interactors, controller, mailer, templates, routes, specs,
   and session revocation.
5. Add auth security notes or TODOs for deferred rate limiting, email
   verification, OAuth linking, and connected accounts.

Rollback during implementation is standard Rails rollback for migrations before
production data exists. After user data exists, destructive rollback must be
handled through a separate data-retention decision.

## Open Questions

- None blocking for Stage 0.
- Before implementing rate limiting, decide whether Routeprint will use an
  existing Rails-native limiter or defer abuse protection to a later change.

