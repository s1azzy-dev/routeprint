## Context

The import foundation already provides `Imports::Source`, `Imports::Run`,
`Imports::RunItem`, the `Imports::StartRun` interactor, and the Solid Queue
execution path. The existing admin area is an Inertia React surface protected
by `Admin::BaseController`, with Pagy-backed tables and a shared shadcn admin
shell.

The new surface is an operational admin screen, so it must be dense, bounded,
translated, and explicit about authorization. Import parameters and raw source
payloads are privacy-sensitive; only the persisted effective parameter
snapshot needed for operator diagnosis is shown, with no artifacts or raw
records exposed.

## Goals / Non-Goals

**Goals:**

- Add the `Imports` navigation section and its `Airports` page.
- Show paginated OurAirports run history with durable progress and status.
- Start a configured full airport import through the existing orchestration.
- Keep admin authorization, Inertia props, i18n, and request/frontend tests
  aligned with current Routeprint patterns.

**Non-Goals:**

- New persistence, source adapters, job behavior, or retry/cancel semantics.
- Editable import configuration, run details, filtering, or bulk controls.
- Displaying raw artifacts, source records, exception messages, or secrets.

## Decisions

### Use a dedicated admin controller and route

Add `Admin::Imports::AirportsController` under
`/admin/imports/airports`, with `index` and `create` actions. This keeps the
admin URL and authorization boundary explicit and leaves the existing import
namespace focused on domain orchestration.

Alternative considered: put the actions in `Admin::AirportsController` because
the source targets airports. Rejected because import runs are operational
records distinct from canonical airport records, and the menu requires a
separate Imports section.

### Reuse `Imports::StartRun` with a fixed source configuration

The controller will load the enabled `ourairports_airports` source and pass the
adapter's server-defined URL/parser values into `Imports::StartRun`, with the
current admin user as initiator. The current migration seeds the source
definition without a URL, so the controller owns these fixed non-secret
parameters until source configuration becomes an explicit product surface. The
route accepts no source, mode, URL, or ownership fields from the client. The
existing active-run guard remains authoritative.

Alternative considered: add a new admin interactor that wraps the start use
case. Rejected for this slice because it would add no independent business
contract; the controller can provide the fixed admin input while
`Imports::StartRun` remains the single import-start use case.

### Keep the table bounded and show sanitized effective parameters

Use Pagy with the existing admin table pattern, ordered newest first. Display
source key, mode, a compact allowlisted parameter summary, status, completed /
failed / total counters, and started/finished timestamps. The parameter
summary is built server-side from safe known keys; arbitrary JSON and raw
payloads are not sent to Inertia.

### Treat expected start failures as operator feedback

On success, redirect back to the index with a translated notice. If the source
is missing/disabled or an active run already exists, redirect with a translated
alert and do not create client-visible exception details. The admin boundary is
enforced by `Admin::BaseController`, and the request spec proves member and
guest denial.

## Risks / Trade-offs

- [A running import can make the start button fail] → Preserve the existing
  source-level active-run guard and show a translated alert.
- [A broad params JSON could disclose source or credential data] → Allowlist
  display fields and never expose raw artifacts or arbitrary parameter hashes.
- [An unbounded history table could grow indefinitely] → Use Pagy pagination
  and select only the fields needed by the page.
- [A source seed/configuration may be absent in a fresh environment] → Treat
  missing or disabled source as an expected failure with no run created.

## Migration Plan

No database migration is required. Deploy routes/controller/page/specs and use
the existing seeded `ourairports_airports` source. Rollback is removing the
new route/controller/page and navigation entry; existing import data and
orchestration remain untouched.

## Open Questions

None for the confirmed MVP scope. Retry, detail, and editable configuration
remain separate future changes.
