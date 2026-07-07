# ADR 0002: Business Frontend Architecture

- Status: Accepted
- Decided: 2026-07-07
- Normalized to implementation: 2026-07-07
- Scope: Rails/Inertia page delivery and the app-owned React, TypeScript, Vite,
  Tailwind frontend boundary.

## Decision

Routeprint uses Rails plus Inertia Rails for page delivery and React,
TypeScript, Vite, Tailwind, and shadcn/ui for application-owned frontend UI.

Rails owns routing, sessions, CSRF, authorization, I18n, business use cases, and
data selection. React owns rendering and local interaction state.

## Consequences

- No separate frontend app.
- No React Router.
- No duplicated frontend route or translation catalog without concrete need.
- Inertia page files orchestrate; feature components and hooks hold UI
  structure and browser lifecycle.
