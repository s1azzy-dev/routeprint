## Context

Routeprint is flight-first, but currently has no user-owned travel persistence.
The accepted domain boundary makes `TravelSegment` the movement root and a
flight its only active MVP specialization. Airport persistence and the
airport-local time architecture already exist; the airline reference catalog is
the final shared-reference dependency before manual flight history.

This design is intentionally preliminary. It records the confirmed ownership,
airport, time, and airline boundaries so they are not lost, but it does not
authorize implementation. The change must return to OpenSpec Explore before
application work begins.

## Goals / Non-Goals

**Goals:**

- Preserve the confirmed private user-owned flight lifecycle.
- Preserve a flight-first `TravelSegment` plus flight-detail boundary.
- Require a relational marketing-airline reference without blocking a user who
  does not know the airline.
- Preserve optional operating-airline and historical marketing-code evidence.
- Keep a flight valid for future map and base statistics regardless of airline
  review or operational state.
- Reuse ADR 0006 for local schedule and absolute-time semantics.

**Non-Goals:**

- Finalize every manual-entry field or validation rule in this preliminary
  artifact.
- Implement routes, models, interactors, UI, migrations, or tests now.
- Render route lines, country fills, statistics, imports, exports, sharing,
  future flights, live status, seats, booking references, aircraft, trips, or
  journals.
- Reopen airline catalog identity or moderation decisions.

## Decisions

### 1. Keep movement identity separate from flight details

`TravelSegment` is the user-owned root and carries ownership plus shared
movement data. `FlightDetail` is a required one-to-one specialization for the
only MVP mode, flight. This follows `docs/FOUNDATIONS.md` and avoids putting
flight-only carrier evidence onto every future transport mode.

The exact field allocation must be finalized after discovery. At minimum, the
segment owns departure/arrival place references and schedule snapshots, while
flight details own marketing/operating carrier associations and the observed
marketing designator.

Alternative: create one `flights` table without a segment root. Rejected because
it conflicts with the established domain boundary and would require migration
before later transport modes.

### 2. Make every travel record explicitly user-owned

The segment belongs to the authenticated user. Create ignores any
client-supplied owner. List, show, update, and delete actions load through the
current user's authorized scope and use explicit policies/interactors.

Exact timestamps and travel history remain private and are returned only in
page-specific allowlisted Inertia props. Public sharing is a separate future
change.

### 3. Require a marketing airline through the system placeholder

`flight_details.marketing_airline_id` is structurally required and references
`airlines`. If the user leaves airline selection empty, the create/update use
case resolves the protected `unknown_airline` by stable system key and supplies
its identifier explicitly. The database has no hard-coded UUID default.

An approved or pending airline is selectable. The pending badge remains visible.
Rejected and merged airlines cannot be newly selected. An optional
`operating_airline_id` captures the actual operator when known.

Alternative: nullable airline foreign key plus free-text fallback. Rejected
because the confirmed product decision prefers complete relational structure
and centralized catalog moderation.

### 4. Preserve observed carrier evidence independently

The flight detail preserves the marketing designator observed on the historical
record when available. This snapshot is not identity and may be null. If a
pending airline is later merged, flight associations move to the approved
target while the observed designator remains unchanged.

If a moderator rejects an airline already referenced by a flight, the flight
remains valid and private. It continues to display the rejected historical
reference, but an edit must replace it with an approved/pending airline or the
unknown system record.

### 5. Airline quality never controls route existence

Departure and arrival airport references are the minimum route evidence used by
future map and base flight-count behavior. Approved, pending, rejected,
inactive, or unknown airline state cannot invalidate an otherwise valid flight
or exclude it from those future route/statistics consumers.

Airline-specific statistics may distinguish approved, pending, rejected, and
unknown evidence, but those outputs belong to the later statistics change.

### 6. Reuse the accepted airport-local time model

Manual flight schedule persistence follows ADR 0006:

- published airport-local civil values;
- departure and arrival IANA zone snapshots;
- resolved absolute instants;
- applied offset evidence;
- explicit unresolved diagnostics when local time cannot be resolved safely.

The upcoming explore cycle must decide which time fields are required for the
manual MVP, how partial historical dates/times behave, and whether unresolved
times block creation or remain reviewable.

### 7. Block implementation until the preliminary artifacts are completed

The first task is another focused OpenSpec Explore cycle. It must replace the
open questions with requirements and scenarios, update proposal/design/specs,
and obtain user approval before red tests, migrations, or application edits.

No new ADR is currently required. ADR 0006 owns time semantics and the airline
catalog ADR will own carrier identity. Promote a new ADR only if later discovery
introduces another durable cross-cutting decision.

## Risks / Trade-offs

- [Preliminary artifacts look implementation-ready] → Keep an explicit discovery
  gate in proposal, design, and tasks; do not invoke apply until the user reviews
  the completed change.
- [The unknown airline hides poor source data] → Make it an explicit display
  option and retain observed designator/source evidence when available.
- [A rejected airline breaks a flight] → Preserve the reference and route;
  require replacement only when that flight is edited.
- [Merge rewrites historical evidence] → Relink the airline association
  transactionally while preserving the observed marketing designator.
- [Travel history leaks across accounts] → Scope every query and mutation by
  owner, cover member/non-owner/guest behavior, and keep Inertia props minimal.
- [Current airport timezone data is historically imperfect] → Preserve segment
  snapshots and explicit uncertainty under ADR 0006; do not silently rewrite
  past history.
- [Unbounded history becomes slow] → Final discovery must define pagination and
  index-backed list ordering before implementation.

## Migration Plan

No production migration is authorized yet.

After discovery completes, the intended additive path is:

1. Add segment and flight-detail tables with ownership, airport, schedule, and
   airline foreign keys.
2. Ensure the protected unknown airline exists before any flight write path is
   enabled.
3. Add interactors, policies, request/system coverage, and frontend behavior
   through red/green slices.
4. Deploy additively; there is no existing flight data to backfill.

Rollback before downstream map/import/export features may remove the additive
flight tables. Once downstream features depend on them, rollback requires a
separate data-preservation plan.

## Open Questions

- Which manual-entry fields are required beyond departure airport, arrival
  airport, and marketing airline?
- Are departure/arrival local date and time both required, and how are partial
  historical values represented?
- How does the form resolve or present ambiguous/nonexistent local civil time?
- What constitutes a duplicate manual-flight candidate?
- What list ordering, pagination, empty state, edit flow, and delete
  confirmation are required?
- Is route distance computed in this change or deferred to map/statistics?
- Which validation messages and bilingual copy are required?
