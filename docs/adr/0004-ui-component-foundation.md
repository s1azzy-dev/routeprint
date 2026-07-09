# ADR 0004: UI Component Foundation

- Status: Accepted
- Decided: 2026-07-07
- Normalized to implementation: 2026-07-07
- Scope: shadcn/ui primitives, Tailwind styling, lucide icons, and
  Routeprint-owned frontend component wrappers.

## Decision

Routeprint uses shadcn/ui primitives, Tailwind, lucide icons, and thin
Routeprint-specific wrappers for repeated application controls.

### Component ownership

The frontend has three component layers:

- `app/frontend/components/ui` contains shadcn-generated primitives and their
  direct support files.
- `app/frontend/components/routeprint` contains Routeprint product
  compositions built from shadcn primitives.
- `app/frontend/pages/**` contains route orchestration, page-specific layout,
  and feature-local components that are not stable shared concepts yet.

Generated shadcn primitives are source-owned application code, but product
styling and domain-specific behavior should normally live in Routeprint
wrappers or feature components instead of repeated edits to generated primitive
internals.

### Development order

Frontend work chooses UI building blocks in this order:

1. Use an installed shadcn primitive, variant, or documented composition.
2. Install another official shadcn primitive when the current product need has
   a good semantic match.
3. Add or reuse a Routeprint wrapper when a product concept, visual treatment,
   or state contract repeats.
4. Create a fully custom control only when shadcn cannot express the required
   semantics, behavior, or map-specific layout.

MapLibre rendering, map lifecycle, and geospatial data behavior remain
feature-owned. The UI kit owns visible controls and compositions around the
map, not the map engine.

### Design and token ownership

Routeprint's travel and map visual language remains the product direction.
Shadcn semantic tokens, states, and component variants must map back to
Routeprint tokens instead of creating a second palette.

The executable token sources are:

- `app/frontend/styles/design_tokens.css`
- `app/frontend/entrypoints/application.css`
- `app/frontend/styles/shadcn-theme.css`

The working design process lives in `docs/frontend/DESIGN_GUIDE.md`. This ADR
owns the UI-kit and component-layer decision; ADR 0002 owns the
Rails/Inertia/React frontend architecture.

## Consequences

- Shared components are added only after at least two current call sites need
  the same contract.
- Routeprint wrappers live under `app/frontend/components/routeprint`.
- Generated primitives need local accessibility and interaction review before
  relying on them in core flows.
- Shared business/admin UI is shadcn-first unless the component boundary makes
  a custom control clearly necessary.
- Updating shadcn components requires source review because generated files are
  local application code.
