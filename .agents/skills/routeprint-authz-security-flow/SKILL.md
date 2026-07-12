---
name: routeprint-authz-security-flow
description: Use this skill when changing Routeprint authentication, sessions, password reset, admin access, user-owned resources, authorization policies, uploads, private media, privacy-sensitive location data, or other security-sensitive Rails flows.
---

# Routeprint Authz Security Flow

## When to use

Use when a task touches account identity, sessions, cookies, password reset, admin surfaces, Pundit policies, ownership checks, uploads/media, private/public visibility, exact user location, logs, credentials, or sensitive headers.

This skill narrows security context. It does not replace `docs/QUALITY_SECURITY.md`.

## Read

- `docs/QUALITY_SECURITY.md` security baseline and the relevant risk matrix row.
- `docs/CONTEXT_MAP.md` row for auth/session/password reset, admin/authorization, or the active feature area.
- `config/routes.rb` for request/controller flows.
- The relevant controller, policy, interactor/model, and matching request/policy/interactor specs.

## Do not read by default

- Unrelated policies or all request specs.
- Product/domain foundations unless product visibility or public/private behavior is ambiguous.
- ADRs unless the task explicitly touches an ADR-owned subsystem.
- Logs, credentials, env files, tokens, or signed blob URLs.

## Procedure

1. Classify risk: auth, password reset, session/cookie, authorization, admin, upload/media, privacy, public catalog/map data, imports/provenance, dependency, or logging/config.
2. Define required proof before editing: owner/non-owner/guest/admin cases, token replay cases, visibility boundary, or no-secret logging check.
3. Keep authorization explicit and centralized through policies; do not trust client-provided ownership or roles.
4. Keep user-facing responses generic where enumeration risk exists.
5. Prove the boundary with the relevant request, policy, or interactor specs; run `make security` when the risk matrix requires it.

## Outputs

```text
Loaded:
Skipped:
Risk:
Approval:
Authorization boundary:
Required proof:
Specs:
Security gate:
Open question:
```

## Token economy

- Open only the risk matrix row and files named by the relevant context-map row.
- Use `rg "authorize|policy|Current.user|signed_id|password_reset|session"` to find the narrow boundary.
- Summarize large request specs by scenario names before reading bodies.
- Do not copy secrets or token-like strings into chat.
