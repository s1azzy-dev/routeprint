# Quality and Security

This document owns security baseline, testing policy, risk checks, and CI/merge
gates. Workflow, commands, and permission routing live in
`docs/DEVELOPMENT.md`. Product and architecture boundaries live in
`docs/FOUNDATIONS.md`.

## Security Baseline

Authentication and sessions:

- Passwords are hashed only.
- Password reset tokens must be single-use and time-bound.
- Invalidate relevant sessions after password reset or security-sensitive
  changes.
- Rotate session identifiers on successful sign in.
- Cookies must be Secure, HttpOnly, and use a deliberate SameSite policy.
- CSRF protection stays enabled for web flows.

Authorization:

- Policy checks are required on user-owned resources.
- Admin surfaces require explicit admin authorization.
- Never trust client-provided ownership or role fields.
- Check edit/delete rights explicitly for trips, travel segments, imports,
  exports, uploads, and future profile/share surfaces.

Uploads and media:

- Validate content type and file size.
- Store uploads through managed Active Storage/application flows.
- Keep private/internal blobs out of public listing surfaces unless explicitly
  published.
- Generate derivatives/previews asynchronously when appropriate.

Privacy:

- Treat exact travel history, future trips, precise timestamps, booking
  references, seats, boarding passes, raw import files, and source payloads as
  privacy-sensitive.
- Do not expose more precision than the product needs.
- Be explicit about what profile and activity data is public.

Secrets and logging:

- No secrets in git.
- Secrets only via env or credentials.
- Never log passwords, reset tokens, signed blob tokens, secrets, or raw
  credentials.
- Filter sensitive parameters and headers.
- Treat Inertia props as a public response surface: keep them page-specific and
  exclude credentials, raw session material, reset tokens, policy internals,
  and unnecessary user attributes.

Abuse protection:

- Public authentication and write endpoints require abuse protection
  appropriate to their risk.
- Known missing controls are tracked in `docs/TODO.md` until implemented through
  an OpenSpec change.

## Risk Matrix

Use this matrix to decide what must be proved for security-sensitive changes.

| Change area | Main risks | Required proof |
| --- | --- | --- |
| Authentication | Account takeover, enumeration, weak credential handling | Request/interactor specs for success and failure paths; no secret/token logging |
| Password reset | Token replay, account enumeration, stale sessions | Single-use/time-bound token coverage; generic user-facing responses; session revocation coverage |
| Sessions/cookies | Fixation, weak cookie policy, stale auth | Rotation or revocation behavior covered; cookie/session settings reviewed |
| Authorization | IDOR, privilege escalation, admin bypass | Policy specs and request specs for owner, non-owner, guest, and admin where relevant |
| Admin surfaces | Unprotected operational tools | Admin-only request coverage and default-deny behavior |
| Uploads/media | Unsafe file exposure, oversized uploads, signed URL leakage | Content type/size validation and publication boundary coverage |
| Travel/location data | Privacy leakage, over-precise public data, future-trip exposure | Precision and visibility decisions explicit in request/system coverage |
| Map/GeoJSON data | Private travel exposure, oversized payloads, N+1 | User-scoped coverage, lean response shape, obvious N+1 review |
| Imports/provenance | Poisoned source data, unsafe retries, lost attribution | Idempotency, source metadata, sanitized errors, and retry behavior covered |
| Dependencies | Known vulnerable packages, unsafe transitive updates | Tradeoff explained; `make security` or equivalent result recorded |
| Logging/config | Secret disclosure, insecure production defaults | Filtered parameters/settings reviewed; no secrets committed |

## Testing Policy

Default stance:

- Integration-first with real PostgreSQL/PostGIS.
- Avoid mocks/stubs for app internals without a strong reason.
- Mocks/stubs are acceptable mainly at external I/O boundaries.
- Prefer request/system coverage for core user journeys.

Required spec layers:

- `spec/models`
- `spec/interactors`
- `spec/policies`
- `spec/requests`
- `spec/system`
- `app/frontend/test`
- `spec/jobs`
- `spec/tooling`
- `spec/bin`

Coverage targets:

- Global line coverage: `>= 90%`.
- Critical domain flows: `>= 95%`.

Critical flows:

- Auth.
- Account ownership and authorization.
- Airport search.
- Manual flight creation/edit/delete.
- Import upload/preview/apply.
- Duplicate detection.
- Map data visibility and payload shape.
- CSV/JSON export.
- Upload security.
- Privacy boundaries.

New protected, upload, location, sharing, or import flows become critical when their
OpenSpec change is approved.

Performance guardrails:

- Watch N+1 in flight lists, map payloads, stats, exports, and profile surfaces.
- Keep airport lookup, route geometry, distance, and map queries index-backed
  when introduced.
- Keep user collections bounded and add pagination before exposing unbounded
  history, import, or export results.
- Keep map payloads lean.

## CI and Merge Gates

Required checks:

- Frontend format check.
- ESLint, including React Hooks and accessibility rules.
- Strict TypeScript typecheck.
- Vitest component tests with coverage reporting.
- Vite production build.
- npm vulnerability audit.
- RuboCop.
- RSpec.
- Brakeman.
- bundler-audit.

Before merge:

- All required checks are green or the known blocker is explicitly accepted.
- Production frontend assets resolve through the Vite manifest, and
  development-only Vite CSP allowances do not leak into production.
- I18n keys exist for `ru` and `en` when user-facing text is introduced.
- Authorization coverage exists for new protected flows.
- New business logic uses the canonical `yabi` interactor style.
- New migrations include required constraints and indexes.
- Geospatial changes are tested against real PostGIS behavior.
- `CHANGES.md` has a short dated summary.
