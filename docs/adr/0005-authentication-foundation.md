# ADR 0005: Authentication Foundation

- Status: Accepted
- Decided: 2026-07-07
- Scope: Account identity, authentication identities, browser sessions,
  password reset, and future identity/integration boundaries.

## Decision

Routeprint ports the Wildwaters authentication foundation as a Routeprint-owned
account boundary built around `User`, `UserIdentity`, and `UserSession`.

`User` represents the Routeprint account. `UserIdentity` represents a way to
authenticate into that account, starting with password authentication and
leaving room for later OAuth login. `UserSession` represents a persistent
browser login session and replaces the Wildwaters `Session` model name to avoid
confusion with Rails controller `session` and cookie sessions.

The first implementation supports password registration, login, logout,
current-session resume, a minimal protected dashboard, and password reset. Raw
session tokens and raw password-reset tokens are never stored; only digests are
persisted. Password reset remains time-bound and single-use.

Email verification is reserved in the schema but not required for early MVP
password login. OAuth, account linking, Gmail/Outlook import, calendar sync,
TripIt-style integrations, and external provider token storage are deferred to
separate OpenSpec changes.

`UserIdentity` is not an external integration store. Future Gmail, Outlook,
calendar, or similar integration credentials belong to a separate
`ConnectedAccount` boundary with explicit consent, scopes, encryption,
disconnect behavior, and token exposure tests.

## Consequences

- Auth implementation work starts from the Wildwaters foundation but adapts
  names, routes, copy, specs, and security checks to Routeprint.
- User-owned travel resources can depend on an explicit authenticated account
  boundary and must still add their own authorization coverage.
- Suspended users must not be able to sign in or continue using existing
  sessions.
- Future OAuth account linking must not silently merge accounts by unverified
  email.
- Rate limiting and mandatory email verification remain explicit follow-up
  decisions unless implemented by an approved later change.

