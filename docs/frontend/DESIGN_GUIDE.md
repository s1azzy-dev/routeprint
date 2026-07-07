# Frontend Design Guide

This guide owns the working frontend design process for Routeprint. ADR 0002
owns the Inertia React frontend architecture, and ADR 0004 owns the shadcn/ui
component foundation.

## Design Workflow

Use this order for application-owned business and admin UI:

1. Define the screen intent and user task.
2. Choose the page structure and responsive behavior.
3. Select existing Routeprint tokens and shadcn primitives.
4. Add or reuse Routeprint wrappers for repeated product concepts.
5. Compose the page from typed React components and Rails-provided Inertia
   props.
6. Verify behavior, accessibility, visual states, and production build output.

Avoid starting from page-local Tailwind classes when the interface needs a
standard button, field, card, table, overlay, empty state, feedback message, or
navigation control.

## Visual Direction

Routeprint should feel like a calm, precise, map-first travel log:

- maps, routes, airports, and user-owned history are the primary surfaces;
- controls should be clear, compact, and touch-friendly;
- panels should feel light, readable, and operational rather than decorative;
- hierarchy should come from spacing, type, surface, and elevation before heavy
  borders;
- color should support travel, geography, and data clarity without becoming a
  one-hue dashboard;
- public/onboarding screens may be more editorial, while admin and import
  screens should be denser and quieter.

Flight-history and map products are layout inspiration, not pixel-matching
targets.

## Component Layers

Use the layers defined by ADR 0004:

- `app/frontend/components/ui`: shadcn-generated primitives and direct support
  files.
- `app/frontend/components/routeprint`: Routeprint wrappers and reusable product
  compositions.
- `app/frontend/pages/**`: route orchestration, page-specific layout, and
  feature-local components that are not stable shared concepts yet.

Page files should stay as route-level orchestration. Move repeated or visually
distinct regions into typed components, and move browser lifecycle concerns
into hooks when that keeps the page readable.

## Shadcn-First Rule

For every new or migrated control:

1. Prefer an installed shadcn primitive and built-in variant.
2. Install another official shadcn primitive when the product need is current
   and the component is a good semantic match.
3. Compose a Routeprint wrapper when the same product concept or state contract
   appears in more than one place.
4. Build a fully custom component only when shadcn cannot express the required
   semantics, behavior, or map-specific layout.

Custom components are allowed for MapLibre canvas integration and other
behavior that a UI kit does not own. The reason should be clear from the
component name, nearby test, or design note.

## Tokens And Styling

The executable token source remains
`app/frontend/styles/design_tokens.css`, loaded through
`app/frontend/entrypoints/application.css`.

Use shadcn semantic colors, radii, focus rings, invalid states, and variants as
the component API. Map those semantics back to Routeprint tokens rather than
introducing raw one-off color ramps.

Prefer `className` for layout and local composition. When the same visual state
or product concept repeats, promote it into a wrapper, variant, or token.

Current default:

- light mode only;
- restrained blue/green route and map accents;
- white or raised surfaces for floating map/admin/import panels;
- restrained radii and shadows;
- accessible focus and invalid states.

## Current Starter Inventory

The first shadcn inventory should cover:

- actions: buttons, icon buttons, dropdown actions;
- forms: labels, fields, inputs, textarea, select, checkbox, radio, switch,
  validation states;
- surfaces: cards, badges, separators, scroll areas;
- overlays: dialog, sheet, drawer, popover, tooltip;
- feedback: alert, toast, skeleton, spinner/progress;
- navigation: tabs, pagination, breadcrumbs where useful;
- data: table scaffolding for admin/import screens;
- route/history cards: compact repeated summaries when current screens need
  them.

Do not add community registry components in the first wave unless a separate
approved change chooses that dependency.

## Rails, I18n, And Tests

Rails continues to own routes, URLs, translated copy, form endpoints, sessions,
CSRF, authorization, and data selection. React components should receive typed
props and submit through the existing Inertia/Rails contracts.

Add or update tests when a component owns behavior, accessibility semantics,
state transitions, validation display, or a public prop contract. Pure visual
replacement can use the narrowest relevant component or browser smoke check.
