# ADR 0004: UI Component Foundation

## Status

Accepted

## Decision

Routeprint uses shadcn/ui primitives, Tailwind, lucide icons, and thin
Routeprint-specific wrappers for repeated application controls.

## Consequences

- Shared components are added only after at least two current call sites need
  the same contract.
- Routeprint wrappers live under `app/frontend/components/routeprint`.
- Generated primitives need local accessibility and interaction review before
  relying on them in core flows.
