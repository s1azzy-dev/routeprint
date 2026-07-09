# ADR 0002: Business Frontend Architecture

- Status: Accepted
- Decided: 2026-07-07
- Normalized to implementation: 2026-07-07
- Scope: Rails/Inertia page delivery and the app-owned React, TypeScript, Vite,
  Tailwind frontend boundary.

## Decision

Routeprint uses Rails plus Inertia Rails for page delivery and React,
TypeScript, Vite, Tailwind, and shadcn/ui for application-owned frontend UI.

### Application boundary

- Rails remains the single application server and owns routes, controllers,
  sessions, CSRF protection, authorization, I18n, business use cases, form
  endpoints, and data selection.
- Inertia is the page-delivery protocol between Rails controllers and React
  pages.
- React owns rendering and local interaction state for application-owned
  business and admin routes.
- Rails supplies page-specific URLs, translated copy, authorization decisions,
  and selected data through typed Inertia props.
- Dedicated JSON endpoints are appropriate only for bounded dynamic data, such
  as a map payload. They do not imply a separate general-purpose public API.
- The frontend does not maintain a second route catalog, translation catalog,
  global state architecture, or general client-query layer without a confirmed
  product need.

### Technology boundary

- Vite builds JavaScript, TypeScript, React, Tailwind, and application-owned
  business CSS.
- TypeScript uses strict checking.
- React components use Tailwind, Routeprint design tokens, and the shadcn/ui
  component foundation selected by ADR 0004.
- npm and the repository lockfile own JavaScript dependency resolution.
- Production browser assets are compiled ahead of time. Routeprint does not
  require a production Node process while SSR is absent.
- Propshaft may continue to serve Rails-owned static assets; it is not a second
  business JavaScript build.

### Rendering boundary

- Application-owned business and admin routes render as client-side Inertia
  pages.
- Legacy Rails-owned infrastructure templates and external engine UI do not set
  the business frontend architecture.
- Page files are route-level orchestration surfaces. Stable controls,
  repeated regions, browser lifecycle, fetch cancellation, and persistence
  concerns move into typed components or local hooks.
- New frontend work must be component-first: a page should compose named
  regions and controls instead of accumulating page-local Tailwind markup.

### Quality boundary

- RSpec request specs prove Rails/Inertia page, prop, redirect, flash,
  authentication, and authorization contracts.
- Vitest and React Testing Library prove user-visible component behavior.
- Accessibility checks cover shared controls, critical forms, and other
  reusable interaction surfaces.
- Frontend format, lint, strict typecheck, unit tests, production build, and
  npm dependency audit are first-class verification gates.

## Consequences

- No separate frontend app.
- No React Router.
- No duplicated frontend route or translation catalog without concrete need.
- Inertia props are a public response surface and require the same review care
  as controller responses.
- Inertia page files orchestrate; feature components and hooks hold UI
  structure, browser lifecycle, and local interaction behavior.
- ADR 0004 owns the UI-kit and component-layer decision. This ADR owns the
  Rails/Inertia/React boundary.
