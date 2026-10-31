## Why

Routeprint has reference catalogs but no way to record a user's own flights.
Manual entry delivers the first complete private product workflow and supplies
travel records for later map, statistics, and import features.

## What Changes

- Add private creation, paginated history, detail, edit, and confirmed deletion.
- Require departure airport, arrival airport, and a complete departure date.
  Departure time, arrival date/time, marketing airline, flight number, and
  operating airline are optional inputs. Empty marketing airline resolves to
  the protected system unknown airline.
- Preserve date-only records without invented midnight timestamps. Preserve
  entered local times and unresolved timezone evidence without inventing UTC
  instants or duration.
- Warn about same-owner/date/route flights and allow explicit confirmation.
  Repeated submission of one creation must not create another record.
- Add bounded authenticated airport lookup and reuse airline selection/submission.
- Exclude map routes, distances/statistics, imports/exports, sharing, upcoming
  flight lifecycle, seats, booking references, aircraft, trips, and journals.

## Capabilities

### New Capabilities

- `manual-flight-history`: Private manual flight lifecycle, catalog selection,
  schedule fidelity, duplicate warning, and safe form submission.

### Modified Capabilities

None. Existing authentication and reference behavior stays intact. Airline
moderation UI remains owned by `add-airline-reference-catalog`.

## Impact

- Add travel-segment/flight-detail persistence, policies, fail-fast interactors,
  queries, presenters, Rails routes, and Inertia/shadcn pages.
- Implement the ADR 0006 resolver with existing TZInfo; no new dependency,
  service, or architectural pattern.
- Protect referenced airports/carriers; preserve carrier evidence through
  rejection and flight-side merge integration.
- Prove ownership, safe props, transactional writes, real database behavior,
  DST/date-line handling, duplicate/replay safety, and bilingual UI.
- Level 2. No new ADR: existing domain/frontend/time boundaries suffice.
  ADR 0009 remains proposed until its airline change is completed.

## Review Status

Confirmed: complete departure date required; other schedule fields optional;
duplicate warning with override; unresolved local times remain saveable; agreed
form fields with operating airline under Additional details.

Approved completion defaults: newest departure date first, 25 rows per page,
same form for edit, cancelable delete confirmation, explicit arrival date when
arrival time is entered, historical departure dates only, and distance deferred.
Validation and lookup bounds are detailed in design/specs. The user approved
all four artifacts before implementation. Runtime completion still requires
the verification and archive steps in tasks.md.
