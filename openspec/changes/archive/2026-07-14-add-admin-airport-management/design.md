## Context

Routeprint already owns the canonical `Place`/`Airport` pair, Inertia React
frontend, Pagy, Pundit, and the shadcn component inventory. Wild Waters provides
the desired admin composition: an admin shell with navigation sections, a quiet
content workspace, table, pagination, and account-menu handoff.

## Goals / Non-Goals

**Goals:**

- Add a single protected admin route rooted at the airport index.
- Keep authorization server-side and default-deny through an admin policy.
- Keep the two-record update atomic and preserve import provenance.
- Use existing shadcn primitives for navigation, table, forms, dialog, alert dialog, and pagination.
- Keep Rails-owned URLs, i18n, validation, redirects, and flash feedback in props/contracts.

**Non-Goals:**

- No airport creation, bulk operations, search, import controls, role management, or dashboard metrics.
- No new dependency, migration, background job, or design-system foundation.
- No editable geometry in v1; the location remains visible/read-only so a malformed coordinate cannot corrupt the catalog.

## Decisions

- **Admin boundary:** use `Admin::BaseController` with a before-action requiring an active admin and an `Admin::AirportPolicy` for index/update/destroy. This keeps the bounded admin guard explicit and gives request/policy proof; client props never decide access.
- **Routes:** make `admin_root` resolve to `admin/airports#index` and expose `resources :airports, only: %i[index update destroy], param: :place_id`. The airport table has no conventional `id`; `place_id` is its primary key.
- **Persistence:** implement one `Admin::UpdateAirport` yabi interactor that validates real input, updates `Place` and `Airport` in one transaction, and maps validation failures to the controller. Destroy through the dependent association and surface `ActiveRecord::DeleteRestrictionError` safely.
- **UI:** copy the Wild Waters shell composition into Routeprint-owned lowercase files, using the installed `Sidebar`-equivalent composition from `Button`, `Separator`, `Badge`, `Table`, `Dialog`, `AlertDialog`, `Field`, `Input`, `Select`, and `Pagination` primitives. A custom sidebar dependency is unnecessary for one screen.
- **Props:** Rails supplies typed row/copy/navigation/url/pagination props; React uses `useForm` for update and Inertia router deletion. The edit dialog owns only transient form state.
- **Pagination:** use existing Pagy offset pagination with a bounded page size and stable `place.name, place_id` ordering. No unbounded catalog payload reaches Inertia.

Alternatives considered: a separate admin SPA would duplicate routing and auth;
ERB/Hotwire would violate the accepted application frontend boundary; a generic
CRUD abstraction would obscure the two-record airport/place contract and is not
needed for one screen.

## Risks / Trade-offs

- [Risk] Deletion can be blocked by import provenance. → Preserve the database restriction, catch it in the controller, and cover the failure path.
- [Risk] Editing canonical fields may be overwritten by a later import. → Keep provenance untouched and leave import conflict policy outside v1.
- [Risk] Admin UI can drift from Wild Waters as both apps evolve. → Reuse the same composition and existing Routeprint shadcn tokens without copying project-specific CSS.
- [Risk] Inertia validation shape differs from the edit dialog's field names. → Add request and component tests for the Rails-owned form contract before the final gate.

## Migration Plan

No database migration. Deploy routes/controllers/policy/interactor and frontend
together. Rollback removes the admin routes and UI; existing airport data and
provenance remain unchanged.

## Open Questions

None for v1. Search, creation, geometry editing, and import controls require a
separate scoped change.
