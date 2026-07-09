# ADRs

Architecture decision records for durable, cross-cutting choices that should
remain understandable after the feature change that introduced them has been
archived.

ADRs may own:

- selected technologies and important dependency boundaries;
- application, persistence, integration, and execution boundaries;
- design-system foundations and durable visual principles;
- constraints, non-goals, rejected alternatives, and consequences;
- scale or replacement triggers when they explain the current architecture
  rather than promise future work.

Feature intent, acceptance behavior, product scenarios, design exploration, and
implementation tasks belong in OpenSpec. Create an ADR only when a confirmed
Level 3 change introduces a decision that should outlive the feature change.

An ADR records the architecture that Routeprint actually adopted. When an old
ADR still contains planning material or contradicts established implementation,
normalize it to the implemented decision and record the normalization date.
Move unimplemented work to `docs/TODO.md`; do not preserve it as an ADR
requirement.

ADRs explain what the project chose and why. They may describe the implemented
shape needed to make that choice concrete, but they do not own endpoint
behavior, acceptance scenarios, rollout steps, implementation checklists, or
feature roadmaps. Exact runtime behavior remains in OpenSpec and is proved by
code and RSpec.

## Index

- [ADR 0001: Map And Geospatial Stack](0001-map-and-geospatial-stack.md)
- [ADR 0002: Business Frontend Architecture](0002-business-frontend-architecture.md)
- [ADR 0003: Import Architecture](0003-import-architecture.md)
- [ADR 0004: UI Component Foundation](0004-ui-component-foundation.md)
- [ADR 0005: Authentication Foundation](0005-authentication-foundation.md)
- [ADR 0006: Time Zone And Flight Schedule Time Handling](0006-time-zone-and-flight-schedule-time-handling.md)

## Header Format

Each ADR starts with a compact technical header:

- `Status` records the decision lifecycle state.
- `Decided` records when Routeprint adopted the decision.
- `Normalized to implementation` records when the ADR was aligned to the
  implemented system rather than aspirational planning.
- `Scope` records the durable boundary owned by the ADR.

Add supersession metadata only when a later accepted ADR actually replaces all
or part of an older decision.
