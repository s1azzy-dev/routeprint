## Context

See proposal.md for outcome and review status. Authentication, Place/Airport,
countries, airline selection/submission, and Inertia/shadcn composition exist.
Travel persistence and member airport lookup do not. Airline moderation remains
unfinished in its own change.

## Goals / Non-Goals

**Goals:** deliver private flight lifecycle with existing Rails/yabi/policy/UI
patterns and preserve incomplete historical schedules.

**Non-Goals:** no generic retry infrastructure, background flight jobs, import
framework, new transport modes/dependencies, admin moderation UI, or map work.

## Decisions

### 1. Atomic relational flight persistence

Use the established TravelSegment root and required one-to-one FlightDetail.
The segment owns user, airport Place references, departure date, optional arrival
date, schedule snapshots/resolution evidence, and creation request identity.
FlightDetail owns required marketing carrier, optional operating carrier,
optional flight number, and historical marketing designator.

Use additive SQL-forward migrations with explicit up/down, uuidv7 identities,
matching foreign keys, required columns, and a unique segment/detail association.
Generate structure.sql through Rails. Create/update segment and detail atomically.
Models hold persistence associations; PrepareEntry owns route, flight-number,
and chronology validation before persistence. HistoryQuery owns read scopes;
page/form presenters own Inertia props and translated field errors.
Protect referenced airport Places and airlines from deletion, including through
existing admin airport deletion. Deleting a flight removes its detail only.
A single flights table conflicts with the existing movement-root boundary.

### 2. Dates represent knowledge

Require an independent complete departure date; arrival date is nullable.
Construct an ADR 0006 local datetime only when date and time are both supplied.
Date-only values have no local datetime, UTC instant, or offset; midnight is not
a substitute for unknown time. Arrival time requires explicit arrival date.

Implement TimeZones::ResolveLocalTime with existing TZInfo. Event states are
date_only, not_provided (arrival omitted), resolved, ambiguous, nonexistent,
and missing_zone. Keep IANA zone snapshots, explicit timestamp-without-time-zone
civil values, resolved timestamptz instants, and offset seconds.
Preserve civil components without browser/server timezone conversion.
Unresolved events retain entered values with null instant/offset; warn only
when a supplied time cannot resolve, not when the time was omitted.

Reject arrival at/before departure only when both instants resolve. Do not
compare local dates as elapsed chronology across zones/date line.
Explicit airport/schedule edits re-resolve affected evidence; unrelated edits
preserve previous snapshots, as do later reference-catalog changes.
No duration cache, automatic historical repair, or timezone jobs.
A UTC-only model loses local/partial information and is rejected under ADR 0006.

### 3. Explicit ownership and narrow use cases

Every action uses explicit policy checks plus current-user scopes. Pass the
trusted user separately from editable input; never accept owner changes.
Missing and other-owner records yield the same not-found response, including
for admins who are not owners. Guests follow existing sign-in redirects.
Keep session and CSRF behavior intact. Inertia props expose only bounded,
page-specific display data, never raw provenance or policy internals.

Controllers orchestrate HTTP. Write use cases use real yabi contracts,
injected collaborators, explicit fail-fast stages, transactions, and narrow
expected failures, following routeprint-yabi-interactor. No broad swallowing
of unexpected exceptions.

### 4. Similar flights and request replay are different

Find candidates by owner, departure date, and ordered airport pair; exclude
the edited flight. Return a bounded safe summary before persistence and require
explicit confirmation for the submitted values. Re-evaluate after form changes;
confirmation never bypasses ordinary validation/authorization.
Route/date is not unique because repeated actual flights remain valid. Exclude
the current creation request from candidate matching so a concurrent replay
reaches the unique-key recovery boundary instead of an unrelated warning.

Issue a fresh opaque UUID per new form and retain it through validation and
duplicate confirmation. Enforce unique (user_id, creation_request_key) on the
segment. Successful same-input replay returns the existing owned flight;
changed-input reuse conflicts rather than silently discarding edits. Keep a
digest of normalized original creation inputs for replay comparison. Cover the
unique-key race with actual database tests and narrow conflict handling.
Disable pending submission in UI, but do not rely on that for persistence safety.
No leases, background jobs, global key store, or generic idempotency service.

### 5. Preserve carrier history without building moderation UI

Resolve blank marketing carrier via the existing unknown-airline stable key.
Both roles accept approved/pending carriers, including inactive historical ones;
new rejected/merged selections fail. Blank operating carrier remains null.
Preserve historical designator/entered flight number independently of identity.
Rejection keeps existing flights readable; later edits require replacing rejected
references. Flight-side relinking handles both roles transactionally and
preserves snapshots, with approved-target and rollback tests.

Full moderator merge endpoints/UI remain in the airline change. If a callable
flight-side relink use case is required now, keep it narrowly domain-owned and
tested; do not claim a full operational moderation workflow exists.
No carrier-state change may delete a flight or its route evidence.

### 6. Bounded selection, history, and form composition

Authenticated airport lookup accepts a 2–100-character normalized IATA/ICAO or
localized/canonical name query and returns at most 20 distinct records. Retained
closed airports remain selectable with a label. Repeated codes require explicit
record choice. Keep search index-backed using existing indexes where applicable;
add only justified indexes after checking query shape. Do not expose raw imports,
coordinates, or admin editing data in picker responses.

History is owner-scoped, departure-date descending then id descending, 25 rows per
page, supported by a composite index and eager-loaded display references.
Create/edit share a feature-local form and reuse the airline picker with departure
date ranking. Operating carrier is under Additional details. Use installed shadcn
controls, Routeprint tokens, typed props, Rails-owned URLs/translations, accessible
labels, field errors, pending states, empty state, and deletion confirmation.
Create/edit redirects to saved detail; deletion returns to history.
Cancellation writes nothing; validation retains form input.

Optional flight number is trimmed/uppercased, limited to 16 ASCII letters/digits,
and does not infer carrier identity. Blank optionals become null.
Airport references must exist; identical endpoints are rejected for this initial
ordinary route workflow. These bounds and completion defaults were approved with the artifacts.

### 7. Scope and verification

This is historical recording, with no upcoming-flight lifecycle, scheduled jobs,
tracking, automatic enrichment, distance calculation, or map payload.
Reject departure dates after today's calendar date at the departure airport;
use the application's UTC date when its zone is unknown. A same-day flight is
allowed without claiming it has already departed. This approved default prevents
an accidental upcoming-flight feature without requiring known clock times.
Schedule precision never determines route existence. All visible copy is ru/en;
warnings describe user action/uncertainty rather than internal diagnostic objects.
No new ADR: use existing domain and ADR 0006 boundaries.

## Risks / Trade-offs

- [History leaks] → ownership scopes/policies, no admin ownership bypass, safe
  allowlisted props, owner/non-owner/guest request and system tests.
- [Invented precision] → separate dates/null timestamps and tests for date-only,
  DST gaps/overlaps, missing zones, overnight and date-line crossings.
- [Partial writes/replays] → atomic writes and actual database race/replay tests;
  independent forms may still add legitimate similar flights after confirmation.
- [Reference corrections rewrite history] → preserve snapshots on unrelated edits
  and protect airport/carrier foreign keys; cover existing admin deletion.
- [Moderation is unfinished] → test flight-side integration separately and retain
  the owning airline change; no false claim of full moderation completion.
- [Query growth] → bounded search/history, eager loading, justified indexes.

## Migration Plan

After artifact approval, add tables/indexes, generate/test the schema, ensure the
system unknown carrier through its existing idempotent bootstrap, then expose
authorized routes and UI via focused red/green slices.
No travel backfill is needed. Before first deployment the additive schema can be
reversed; after users enter flights, rollback must preserve/restore their data,
not routinely drop it. Run full project gates before publication.

## Approval Gate

The user approved the completed proposal, design, specs, and tasks, including
completion defaults and validation bounds, before implementation. Task 1.2
records that gate; subsequent implementation must preserve this accepted intent.
