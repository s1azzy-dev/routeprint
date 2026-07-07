# Bootstrap Foundation Specification

## Purpose

Routeprint starts with a clean project foundation before any business flight
behavior is implemented.

## Requirements

### Requirement: Runtime Foundation

Routeprint SHALL boot as a Rails/PostGIS monolith with Inertia, React,
TypeScript, Tailwind, shadcn/ui, Docker, Make, RSpec, Vitest, OpenSpec, and
security tooling initialized.

#### Scenario: Empty application shell

- **WHEN** a user requests the root page
- **THEN** the application renders the `Home/Show` Inertia component
- **AND** the component receives only bootstrap-safe Routeprint props

### Requirement: Harness Foundation

Routeprint SHALL route repository work through the SDD gate, project
documentation, OpenSpec artifacts, ADRs, Make/container commands, and
verification matrix before the first business task.

#### Scenario: Agent task routing

- **WHEN** an agent starts repository work
- **THEN** `AGENTS.md` points to the owning workflow, context, product,
  security, OpenSpec, TODO, and ADR documents
- **AND** runtime commands are selected through the documented Make/container
  contract
