# manual-flight-history Specification

## Purpose
Define private manual flight recording, editing and deletion with faithful
airport-local dates/times, catalog selection, and safe duplicate handling.

## Requirements

### Requirement: Flight history is private and user-owned

The system SHALL assign flights to the authenticated current user and explicitly
authorize every list, read, create, update, and delete action. Client input SHALL
NOT choose or change ownership. Admin role alone SHALL NOT grant access.

#### Scenario: Create for current user

- **WHEN** a member submits a valid flight, including a client-supplied owner
- **THEN** only the current user's ownership is persisted or the extra input is rejected
- **AND** one flight and its flight details are created atomically

#### Scenario: Cross-user access is indistinguishable from missing data

- **GIVEN** another user owns a flight
- **WHEN** a member or non-owning admin reads, edits, updates, or deletes it
- **THEN** the response is the same not-found response as a missing identifier
- **AND** no record or private attributes are returned or changed

#### Scenario: Guest accesses flights

- **WHEN** a guest requests any flight page or write action
- **THEN** the guest is redirected to sign in without exposure or mutation of travel data

### Requirement: A flight requires an airport route and departure date

The system SHALL require two distinct existing airport references and a complete
valid departure calendar date. Time, arrival date/time, carrier selection,
flight number, and operating carrier SHALL be optional form inputs.
Month-only or year-only dates SHALL NOT be accepted.

#### Scenario: Save minimal historical evidence

- **WHEN** the owner submits two airports and a complete departure date only
- **THEN** the flight saves successfully with no invented arrival date or time
- **AND** empty marketing carrier resolves to the system unknown airline

#### Scenario: Reject incomplete or invalid route evidence

- **WHEN** the user omits an airport/date, chooses a non-airport or nonexistent
  reference, chooses identical endpoints, or supplies an invalid/partial date
- **THEN** the form reports field errors and preserves input without partial writes

#### Scenario: Reference a historical closed airport

- **WHEN** the user chooses a retained closed airport
- **THEN** it remains usable for the saved historical flight

#### Scenario: Reject future departure dates

- **WHEN** departure date is after today's date in the departure airport's zone,
  or after today's UTC date when the airport zone is absent
- **THEN** a departure-date field error prevents saving
- **AND** a same-day date remains allowed without requiring a departure time

### Requirement: Airport selection is authenticated and bounded

The system SHALL offer authenticated lookup by IATA, ICAO, canonical name, or
localized name for queries of 2–100 characters, returning at most 20 records.
Options SHALL distinguish airports by identifier, name, public codes, country,
and closed status without exposing raw source evidence.

#### Scenario: Search by code or name

- **WHEN** a member searches with a valid normalized code or supported name
- **THEN** matching airports are offered within the result limit
- **AND** duplicate codes remain distinct choices rather than automatic identity matches

#### Scenario: Reject invalid lookup input or unauthenticated use

- **WHEN** a query is malformed/outside the length bounds or a guest requests lookup
- **THEN** the request is rejected or follows the existing authentication redirect
- **AND** an unbounded catalog or raw provenance is not returned

### Requirement: Date-only records preserve their precision

The system SHALL retain departure and optional arrival dates independently from
timestamps. Omitted times SHALL NOT become midnight, resolved instants, offsets,
or warnings. Arrival time SHALL require an explicit arrival date.

#### Scenario: Keep date-only evidence

- **WHEN** a member saves a flight without either time
- **THEN** the exact entered dates remain visible with no fabricated clock time
- **AND** no unresolved-time warning or elapsed duration is displayed

#### Scenario: Arrival time has no date

- **WHEN** a member enters arrival time without arrival date
- **THEN** a translated arrival-date field error prevents saving
- **AND** the system does not infer overnight arrival

### Requirement: Airport-local time is preserved and conservatively resolved

The system SHALL preserve supplied airport-local civil values, event-specific
IANA zone snapshots, safely resolved UTC instants and applied offsets under
ADR 0006. Ambiguous, nonexistent, or missing-zone times SHALL remain saveable
with explicit uncertainty and without invented instants or duration.

#### Scenario: Resolve known local times

- **WHEN** valid local dates/times have unambiguous airport zones
- **THEN** the system retains both local evidence and resolved instants/offsets
- **AND** display uses each airport's local values regardless of browser timezone

#### Scenario: Preserve DST or missing-zone uncertainty

- **WHEN** a supplied time falls in a DST overlap/gap or lacks a usable zone
- **THEN** the flight saves with its entered local values and explicit uncertainty
- **AND** the affected instant/offset remain absent
- **AND** translated feedback explains that exact time is unresolved

#### Scenario: Validate resolved chronology across the date line

- **WHEN** both events resolve to instants
- **THEN** arrival must be strictly later than departure
- **AND** an earlier arrival local calendar date is accepted when absolute chronology is valid

#### Scenario: Incomplete chronology

- **WHEN** either event has no resolved instant
- **THEN** no duration or invalid chronology is inferred by subtracting local dates/times

#### Scenario: Preserve snapshots on unrelated edits

- **GIVEN** airport catalog timezones changed after a flight was saved
- **WHEN** its owner reads it or edits only the flight number/carrier
- **THEN** original schedule/zone/resolution evidence stays unchanged
- **AND** an explicit airport or schedule edit re-resolves the affected event

### Requirement: Carrier selection reuses the reference catalog

The system SHALL persist a required marketing carrier, using the protected
unknown airline for empty input, and an optional operating carrier. Approved or
visibly pending carriers, including inactive historical ones, SHALL be selectable;
rejected/merged carriers SHALL NOT be newly assigned.

#### Scenario: Unknown and codeshare carriers

- **WHEN** the user leaves marketing carrier empty and operating carrier omitted
- **THEN** the flight uses the stable system unknown marketing carrier and no operator
- **AND** choosing different valid marketing/operating carriers persists both roles

#### Scenario: Submit a missing airline

- **WHEN** the user explicitly submits a missing airline through the existing picker
- **THEN** the existing authenticated pending-candidate flow is reused
- **AND** the candidate's pending status remains visible when selected

#### Scenario: Invalid carrier assignment

- **WHEN** either role references a nonexistent, rejected, or merged carrier
- **THEN** field validation prevents persistence without losing entered form data

### Requirement: Historical carrier evidence survives catalog changes

The system SHALL retain optional historical marketing designator evidence and
flight number independently from current carrier identity. Rejection SHALL NOT
remove a flight. A catalog merge SHALL relink carrier references transactionally
without overwriting observed evidence.

#### Scenario: Relink merged carrier references

- **GIVEN** flights reference a pending carrier in either role and retain historical evidence
- **WHEN** the catalog merge operation relinks it to an approved target
- **THEN** affected associations point to that target and evidence stays unchanged
- **AND** failure rolls back the relinking operation

#### Scenario: Read and edit a rejected reference

- **GIVEN** a flight references a subsequently rejected carrier
- **WHEN** its owner reads the flight
- **THEN** the flight remains private and readable with its route and reference
- **AND** a later submitted edit must replace rejected roles with allowed selections

#### Scenario: Protect referenced catalog records

- **WHEN** an existing admin airport delete or catalog deletion targets a referenced record
- **THEN** deletion is refused without deleting or damaging the flight

### Requirement: Flight number is optional bounded evidence

The system SHALL allow a blank flight number or at most 16 ASCII letters/digits,
trimmed and uppercased. It SHALL NOT infer or require carrier identity from it.

#### Scenario: Store or reject a number

- **WHEN** a user supplies a valid number or leaves it blank
- **THEN** it is normalized and saved or stored as absent, respectively
- **AND** malformed/oversized values instead return a field error without partial writes

### Requirement: Similar flights require deliberate confirmation

The system SHALL warn before creating/updating a flight whose owner, departure
date, and ordered airport pair match another owned flight. Confirmation SHALL
allow legitimate repeats without bypassing validation. The edited flight SHALL
be excluded from its own candidate search.

#### Scenario: Confirm a legitimate repeated route

- **GIVEN** a same-owner/date/route flight exists
- **WHEN** a member submits another matching flight
- **THEN** a bounded private candidate summary and explicit confirmation are shown before writing
- **AND** confirmation saves the additional flight

#### Scenario: Changed input and private candidate scope

- **WHEN** route/date values change after a warning
- **THEN** matching is evaluated for the new values
- **AND** another user's records never cause warnings or appear in candidates

### Requirement: Replaying one creation does not create another flight

The system SHALL distinguish a fresh creation from a retry of the same form.
Repeated or concurrent successful submission of the same creation and values
SHALL yield one owned record. Reusing that request identity with different
creation values SHALL return a conflict rather than discard edits.

#### Scenario: Double submit or retry

- **WHEN** the same creation is submitted twice, concurrently, or retried after success
- **THEN** both successful responses identify the same owned flight
- **AND** there is only one segment/detail pair

#### Scenario: Preserve form identity across validation and confirmation

- **WHEN** validation or duplicate warning requires another submission
- **THEN** the same creation identity is retained until save succeeds
- **AND** a new independent form may create another flight after required confirmation

### Requirement: History is bounded and editable

The system SHALL display only the owner's flights ordered by departure local
date descending with stable identifier ordering, in pages of 25. It SHALL offer
detail, the same editable input fields, and deliberate cancelable deletion.

#### Scenario: Browse or start an empty history

- **WHEN** the owner opens history
- **THEN** only the requested bounded page is returned with navigation and display references
- **AND** an empty collection offers an Add flight action

#### Scenario: Save an edit

- **WHEN** the owner submits a valid edited flight
- **THEN** changes save atomically and the saved detail is shown
- **AND** invalid edits leave the original flight unchanged with input and errors retained

#### Scenario: Confirm or cancel deletion

- **WHEN** the owner requests deletion
- **THEN** confirmation is required
- **AND** cancellation changes nothing
- **AND** confirmation deletes the flight/detail and returns to history without deleting catalogs

### Requirement: Forms expose accessible bilingual behavior

The system SHALL provide labeled controls, translated ru/en feedback and field
errors, pending submission state, preserved invalid input, and an Additional
details section for the optional operator. Responses SHALL exclude unnecessary
account data, raw imports, and policy internals.

#### Scenario: Complete the minimal form

- **WHEN** the user selects airports and a departure date with keyboard-accessible controls
- **THEN** save creates the flight and shows its saved detail
- **AND** the pending action is disabled while a submission is in progress

#### Scenario: Correct a form error or unresolved time

- **WHEN** validation fails or supplied local time cannot resolve
- **THEN** input and selected references remain visible
- **AND** translated errors/warnings appear with the relevant field or schedule
