# Routeprint

<a href="https://github.com/s1azzy-dev/routeprint/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/s1azzy-dev/routeprint/actions/workflows/ci.yml/badge.svg?branch=main" height="28"></a>
<img alt="Coverage" src="https://img.shields.io/badge/Coverage-SimpleCov-0ea5e9?style=for-the-badge" height="28">

Routeprint is a Rails/PostGIS monolith for personal travel history and travel
maps, starting with flight history.

MVP direction:

```text
Import your flight history, see every route on your personal map, keep your
travel data under your control.
```

## Documentation Map

| Need | Read |
| --- | --- |
| Context loading by task area | [`docs/CONTEXT_MAP.md`](docs/CONTEXT_MAP.md) |
| Agent workflow, commands, permissions, verification | [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) |
| Product scope, architecture, domain, database, PostGIS | [`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md) |
| Security, testing policy, CI and merge gates | [`docs/QUALITY_SECURITY.md`](docs/QUALITY_SECURITY.md) |
| Bootstrap completion plan and evidence | [`docs/INITIALIZATION_PLAN.md`](docs/INITIALIZATION_PLAN.md) |
| Current feature specifications and active changes | [`openspec/`](openspec/) |
| Prioritized unimplemented work | [`docs/TODO.md`](docs/TODO.md) |
| Architecture decisions | [`docs/adr/`](docs/adr/) |
| Frontend design workflow | [`docs/frontend/DESIGN_GUIDE.md`](docs/frontend/DESIGN_GUIDE.md) |
| Change history | [`CHANGES.md`](CHANGES.md) |

## Local Bootstrap

Prefer the Makefile workflow documented in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

```bash
make setup
make doctor
make verify-fast
```

Useful local targets:

- `make up` - start local containers in the foreground
- `make down` - stop local containers
- `make logs` - view web container logs
- `make bash` - shell into the web container
- `make shell` - open Rails console in the web container
- `make lint` - run RuboCop with autocorrect
- `make test` - run the full test suite
- `make security` - run bundler-audit and Brakeman
- `make frontend-verify` - run all frontend quality and build gates
- `make verify` - run the full local verification gate

Default host ports:

- Rails: `http://localhost:3001`
- Vite dev server: `http://localhost:3038`
- PostgreSQL/PostGIS: `localhost:5433`

## Current Runtime Foundation

The initialized project currently includes:

- Rails 8.1.3
- Ruby 4.0.5
- PostgreSQL 18 with PostGIS 3.6
- Inertia Rails
- React 19
- TypeScript 6
- Vite 8
- Tailwind 4
- shadcn/ui primitives
- RSpec, SimpleCov, RuboCop
- Vitest and React Testing Library
- Brakeman and bundler-audit
- OpenSpec
- Docker Compose and devcontainer support
- RTK-backed agent/verification commands

The root page intentionally renders only a minimal Routeprint Inertia React
shell. Flight, airport, import, map, statistics, export, auth, and admin product
behavior should be added later through SDD/OpenSpec slices.

## Spec-Driven Changes

Use `$routeprint-spec-driven-change` to choose the workflow:

| Level | Typical work | Artifacts |
| --- | --- | --- |
| 1 | Copy, visual polish, narrow bug or refactor | None; use the normal project loop |
| 2 | Meaningful feature or uncertain behavior | OpenSpec proposal, specs, design, and tasks |
| 3 | Durable cross-cutting architecture change | Level 2 plus a focused ADR |

Level 2 and 3 flow:

```text
explore -> confirm -> propose -> review -> apply -> verify -> archive
```

OpenSpec records current observable behavior and pending behavior changes. ADRs
record durable technology choices, system boundaries, execution and persistence
models, and design-system foundations. Future work that has not become a
change lives in `docs/TODO.md`.

New or changed behavior uses the Level 2 or 3 delta flow. RSpec, project
skills, permissions, and Make verification remain implementation proof.

```bash
bin/openspec list
bin/openspec list --specs
make openspec-validate
make openspec-update
```

## First Product Slices

Do not start with feature enthusiasm. The intended order is:

```text
bootstrap -> auth -> airports -> manual flights -> map -> CSV import ->
App in the Air import -> export -> launch
```

`docs/TODO.md` is the queue, not acceptance criteria. Each business slice should
start from the SDD gate and use OpenSpec/ADR when required.

## Notes

- The app is configured for PostgreSQL/PostGIS from the start.
- Local Docker and CI use `postgis/postgis`, based on the official `postgres`
  image with PostGIS extensions installed.
- For PostgreSQL 18, the container volume path is `/var/lib/postgresql`, not the
  older `/var/lib/postgresql/data`.
- MVP behavior remains flight-only even though the persistence model may later
  support broader `travel_segments.transport_mode` values.
