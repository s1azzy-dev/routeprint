# auth-foundation Specification

## Purpose
Owns the implemented Routeprint account identity, password authentication,
browser session, password reset, and deferred identity-integration boundaries.

## Requirements
### Requirement: Account Identity
Routeprint SHALL persist account-level identity separately from authentication
methods and SHALL normalize account email addresses before validation.

#### Scenario: Register account identity
- **WHEN** a visitor registers with a valid email, display name, locale, and password
- **THEN** Routeprint creates a user with a normalized unique primary email
- **AND** the user has the default member role and active status

#### Scenario: Reject duplicate account email
- **GIVEN** an account already exists for an email address
- **WHEN** a visitor registers with the same email using different casing or whitespace
- **THEN** Routeprint rejects the registration without creating a second user

#### Scenario: Suspend account
- **GIVEN** a user has suspended status
- **WHEN** Routeprint evaluates account status
- **THEN** the user is treated as suspended and not active for authentication

### Requirement: Authentication Identity
Routeprint SHALL store login methods in user identities and SHALL keep external
integration tokens out of those identities.

#### Scenario: Password identity
- **WHEN** a user registers with a password
- **THEN** Routeprint creates one password identity for the user
- **AND** the password is stored as a password digest only

#### Scenario: Password policy
- **WHEN** a user sets or changes a password shorter than 12 characters
- **THEN** Routeprint rejects the password

#### Scenario: Future external identity shape
- **WHEN** a non-password identity is created by a future change
- **THEN** Routeprint requires a provider UID for that identity
- **AND** Routeprint does not store Gmail, Outlook, calendar, or import tokens in `user_identities`

### Requirement: User Session
Routeprint SHALL persist browser login sessions in `user_sessions` and SHALL
store only a digest of the session token.

#### Scenario: Issue session
- **WHEN** a user successfully authenticates
- **THEN** Routeprint creates a user session with an authentication method, expiry time, last-seen time, and token digest
- **AND** Routeprint returns the raw session token only through a signed HTTP-only cookie

#### Scenario: Resume active session
- **GIVEN** a request includes a valid current user-session cookie
- **WHEN** the user session is active and the user is active
- **THEN** Routeprint authenticates the request as that user

#### Scenario: Reject revoked session
- **GIVEN** a request includes a cookie for a revoked user session
- **WHEN** Routeprint resumes authentication
- **THEN** Routeprint clears the cookie and treats the request as anonymous

#### Scenario: Reject suspended user session
- **GIVEN** a request includes a valid cookie for a suspended user
- **WHEN** Routeprint resumes authentication
- **THEN** Routeprint clears the cookie and treats the request as anonymous

#### Scenario: Throttle last-seen update
- **GIVEN** a user session was seen recently
- **WHEN** the user makes another authenticated request
- **THEN** Routeprint does not update `last_seen_at`

#### Scenario: Refresh stale last-seen update
- **GIVEN** a user session has not been seen within the configured touch interval
- **WHEN** the user makes an authenticated request
- **THEN** Routeprint updates `last_seen_at`

### Requirement: Password Authentication
Routeprint SHALL support password registration, login, logout, and protected
page access without exposing sensitive failure details.

#### Scenario: Register with password
- **WHEN** a visitor submits valid registration credentials
- **THEN** Routeprint creates the account, creates a password identity, signs the user in, and redirects to a protected Routeprint page

#### Scenario: Reject invalid registration
- **WHEN** a visitor submits an invalid email or password
- **THEN** Routeprint keeps the visitor anonymous and returns validation errors without creating an account

#### Scenario: Sign in with password
- **GIVEN** an active user has a password identity
- **WHEN** the visitor submits valid login credentials
- **THEN** Routeprint signs the user in and creates a fresh user session

#### Scenario: Reject invalid login
- **WHEN** a visitor submits an unknown email or incorrect password
- **THEN** Routeprint rejects the login with a generic credentials error

#### Scenario: Reject suspended login
- **GIVEN** a user has suspended status
- **WHEN** the user submits otherwise valid login credentials
- **THEN** Routeprint rejects the login with the same generic credentials error used for invalid login

#### Scenario: Sign out
- **GIVEN** a user is signed in
- **WHEN** the user signs out
- **THEN** Routeprint revokes the current user session and clears the user-session cookie

#### Scenario: Protect dashboard
- **WHEN** an anonymous visitor requests the dashboard
- **THEN** Routeprint redirects the visitor to sign in

#### Scenario: Access dashboard
- **GIVEN** a user is signed in
- **WHEN** the user requests the dashboard
- **THEN** Routeprint renders the dashboard for that user without exposing session tokens in Inertia props

### Requirement: Password Reset
Routeprint SHALL support digest-backed, time-bound, single-use password reset
for password identities without account enumeration.

#### Scenario: Request reset for existing account
- **GIVEN** a password account exists for an email address
- **WHEN** a visitor requests a password reset for that email
- **THEN** Routeprint stores a reset token digest and timestamp
- **AND** Routeprint sends a reset email containing the transient raw token
- **AND** Routeprint returns a generic success response

#### Scenario: Request reset for unknown account
- **WHEN** a visitor requests a password reset for an unknown email
- **THEN** Routeprint returns the same generic success response
- **AND** Routeprint does not reveal whether the account exists

#### Scenario: Consume valid reset token
- **GIVEN** a password identity has a current reset token digest
- **WHEN** the user submits the matching raw reset token and a valid new password
- **THEN** Routeprint updates the password, clears the reset digest and timestamp, revokes existing user sessions, and allows future login with the new password

#### Scenario: Reject expired reset token
- **GIVEN** a password identity has an expired reset token digest
- **WHEN** the user submits the matching raw reset token
- **THEN** Routeprint rejects the reset without changing the password

#### Scenario: Reject invalid reset token
- **WHEN** the user submits an invalid reset token
- **THEN** Routeprint rejects the reset without revealing account existence

### Requirement: Deferred Identity Integrations
Routeprint SHALL reserve future identity and integration boundaries without
implementing them as part of the password-auth MVP.

#### Scenario: Email verification reserved
- **WHEN** Routeprint creates account and identity records
- **THEN** the data model can record primary email verification state
- **AND** Routeprint does not require verified email for MVP password login

#### Scenario: OAuth deferred
- **WHEN** the auth foundation is complete
- **THEN** Routeprint has not implemented OAuth login or account linking
- **AND** any future OAuth implementation requires a separate OpenSpec change

#### Scenario: Connected accounts deferred
- **WHEN** the auth foundation is complete
- **THEN** Routeprint has not implemented connected accounts or external provider token storage
- **AND** any future Gmail, Outlook, calendar, TripIt, or similar integration requires a separate OpenSpec change
