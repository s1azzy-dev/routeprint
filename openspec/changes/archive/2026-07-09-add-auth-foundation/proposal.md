## Why

Routeprint needs an account and authentication foundation before user-owned
travel history can be built safely. Wildwaters already has a proven Rails auth
shape, and Routeprint should port that foundation deliberately while preserving
Routeprint privacy, session, and future integration boundaries.

## What Changes

- Add the durable Routeprint auth architecture decision in ADR 0005.
- Introduce password-based account registration, login, logout, current session,
  and password reset as the first authentication foundation.
- Store account identity in `users`, login identities in `user_identities`, and
  persistent browser sessions in `user_sessions`.
- Rename the Wildwaters `Session` model shape to `UserSession` for Routeprint.
- Store only digest-backed session and password-reset tokens.
- Add a minimal protected dashboard so the auth/session boundary has a real
  request surface.
- Reserve, but do not implement, email verification, OAuth login, external
  connected accounts, Gmail/Outlook import, public API, native mobile, live
  tracking, or AI features.

## Capabilities

### New Capabilities

- `auth-foundation`: Account identity, password credentials, browser sessions,
  password reset, protected-page access, and deferred identity/integration
  boundaries.

### Modified Capabilities

- None.

## Impact

- Affected runtime areas: models, migrations, auth interactors, controllers,
  routes, mailer, minimal Inertia auth/dashboard pages, request/model/interactor
  specs, and frontend page tests where UI is introduced.
- Affected security areas: password policy, session cookies, token persistence,
  suspended-user handling, password reset enumeration resistance, and future
  user-owned travel-resource authorization preconditions.
- Affected documentation: ADR index, auth foundation ADR, `CHANGES.md`, and the
  archived `auth-foundation` capability after implementation.
- No new external services, OAuth providers, gems, packages, or connected
  account token storage are introduced by this change.

