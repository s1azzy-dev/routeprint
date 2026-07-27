## Why

Manual flight history is Routeprint's first user-owned product slice and the
source of the route lines and statistics that define the MVP. This preliminary
change preserves the confirmed airline integration and product boundary now,
while deferring unresolved flight-form and persistence detail until the team
returns to implement the slice.

## What Changes

- Add private user-owned travel segments with a flight specialization for
  manually recorded historical flights.
- Require departure and arrival airports and preserve airport-local schedule
  semantics under ADR 0006.
- Require a marketing-airline reference; when the user leaves the airline
  field empty, the create use case assigns the protected system
  `unknown_airline`.
- Allow an optional operating airline for codeshare or wet-lease history.
- Reuse approved and clearly labelled pending airlines from the airline
  reference catalog and allow an authenticated user to submit a missing global
  candidate through that catalog boundary.
- Add authorized create, read, update, and delete behavior for only the current
  user's flight history.
- Keep map rendering, route statistics, CSV/App in the Air imports, sharing,
  future-flight behavior, live status, booking references, seats, and aircraft
  detail outside this slice.
- Mark the change as discovery-incomplete: implementation must not begin until
  the remaining manual-entry fields, validation rules, list behavior, and
  timezone-resolution acceptance scenarios are confirmed and the artifacts are
  updated.

## Capabilities

### New Capabilities

- `manual-flight-history`: Private manual flight persistence and authorized
  lifecycle behavior, including confirmed airport, time, and airline
  boundaries.

### Modified Capabilities

None.

## Impact

- Will add user-owned travel-segment and flight-detail persistence, interactors,
  policies, routes/controllers, Inertia pages, presenters, and integration
  tests when the deferred discovery is completed.
- Depends on the airport reference foundation, ADR 0006 time handling, the
  completed airline reference catalog, and explicit authorization for every
  user-owned record.
- Creates no implementation authorization in its present preliminary state.

This is currently a Level 2 change. Existing ADR 0006 owns the durable time
model, and the airline catalog change owns carrier identity; no new ADR is
required unless later discovery introduces another durable cross-cutting
decision.

## Assumptions And Unresolved Questions

- Confirm the minimal required and optional manual-entry fields beyond airports,
  schedule, and carrier associations.
- Confirm handling of incomplete historical dates/times, timezone ambiguity,
  overnight/date-line arrival, and duration evidence.
- Confirm duplicate-candidate behavior, flight-list ordering/pagination, edit
  semantics, deletion confirmation, and validation copy.
- Confirm whether route distance is computed during this slice or deferred to
  the map/statistics change.
- Re-enter OpenSpec Explore and replace these unresolved points with explicit
  requirements before implementation.
