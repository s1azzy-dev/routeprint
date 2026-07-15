## Why

Routeprint already persists reference-data import runs and executes them through
Solid Queue, but administrators cannot inspect that history or start the
OurAirports catalog import from the application. This change adds the smallest
operational UI needed to make the existing import subsystem usable.

This is a Level 2 specified feature. It changes protected admin behavior but
does not introduce a durable architectural decision, so no ADR is required.

## What Changes

- Add an `Imports` section to the admin left navigation with an `Airports` item.
- Add a paginated admin table of OurAirports airport import runs showing source,
  mode, persisted parameters, status, progress counters, and timestamps.
- Add an admin action that starts one preconfigured full OurAirports airport
  import through the existing `Imports::StartRun` use case.
- Show success and expected failure feedback when an import is started.
- Add admin authorization, request, and frontend coverage for the new flow.

### Scope

- The start action uses the existing `ourairports_airports` source and
  server-defined adapter configuration; the page does not edit import
  parameters.
- Runs are displayed as operational history only; there is no run detail page,
  retry action, cancellation, filtering, or bulk operation in this slice.

### Non-Goals

- User-owned flight imports or upload flows.
- New import sources, migrations, queue behavior, or persistence fields.
- Changes to the existing import processor, retry semantics, or provenance
  model.

## Capabilities

### New Capabilities

- `admin-imports-ui`: Admin navigation, airport import history, and starting a
  preconfigured OurAirports airport import.

### Modified Capabilities

- None.

## Impact

- Rails admin routes, controller, policy, and Inertia props.
- React admin navigation and an imports table page using existing shadcn
  primitives and Pagy pagination.
- Existing `Imports::StartRun` orchestration and Solid Queue jobs are reused;
  no new dependency, service, or migration is needed.
- Request, policy, frontend, and security verification surfaces are added.
