## Why

Routeprint has a canonical airport catalog but no protected operational surface
for correcting or removing records. Admins need a small, safe workspace to keep
that catalog usable while the public product remains flight-first.

## What Changes

- Add an admin-only area with a Wild Waters-inspired left navigation and central workspace.
- Expose an `Admin` account-menu item only when Rails provides an admin URL.
- Add a paginated airport list with localized labels and empty state.
- Allow admins to edit catalog fields, save changes, and delete airports with confirmation.
- Keep creation, import orchestration, search, bulk actions, and non-admin access out of v1.

## Capabilities

### New Capabilities

- `admin-airport-management`: Admin authorization, airport catalog listing, editing, saving, and deletion.

### Modified Capabilities

- None.

## Impact

- Rails routes, admin controllers, policy, airport update interactor, request/policy specs, and i18n.
- Inertia shell props and account dropdown.
- React admin layout, airport table, edit dialog, delete confirmation, pagination, and tests.
- No new dependencies or migrations; existing Pagy, Pundit, Inertia, React, and shadcn primitives are reused.

This is a Level 2 specified feature. No ADR is required because it uses the
accepted Routeprint frontend, shadcn, policy, and interactor boundaries.
