# ADR 0006: Time Zone And Flight Schedule Time Handling

- Status: Accepted
- Decided: 2026-07-10
- Scope: Temporal data semantics for places, travel segments, flight imports,
  duration calculations, and airport-local display.

## Context

Flight schedules are published in the local civil time of the departure or
arrival airport. A local wall-clock value is not an absolute point on the
timeline until it is interpreted with an IANA time zone. The two concepts must
remain separate:

- `2026-10-25 22:30` at `Europe/Istanbul` is a local civil datetime;
- the resulting UTC instant is an absolute point in time;
- the IANA zone is the rule set used to interpret the local value;
- the UTC offset used for that interpretation is useful audit evidence, but is
  not a time-zone identity.

Routeprint needs all of these concepts for correct cross-border duration
calculation, airport-local display, imports, future scheduled flights, and
repairable provenance. PostgreSQL `timestamptz` stores an instant internally
as UTC but does not retain the original IANA zone, so a UTC column alone cannot
reconstruct the published airport-local schedule.

## Decision

Routeprint uses a dual representation for scheduled travel times:

1. Store the published airport-local schedule as a local civil datetime in an
   explicit `timestamp without time zone` column named `*_local_at`.
2. Store the IANA time-zone identifier used for that event directly on the
   travel segment, separately for departure and arrival.
3. Store the resolved absolute instant in a `timestamptz` column named `*_at`.
4. Store the applied UTC offset in seconds as an audit snapshot. It supports
   diagnostics and historical inspection; it never replaces the IANA zone.

The application treats UTC as its default execution and persistence context:

- domain columns representing absolute instants use PostgreSQL `timestamptz`;
- Rails uses UTC application/default Active Record time behavior;
- local civil columns are explicit exceptions and must be declared as
  `timestamp without time zone`;
- actual operational timestamps, audit timestamps, and system timestamps are
  absolute instants; a source that provides an actual time only as local civil
  data must pass through the same explicit resolution boundary;
- framework-owned operational metadata, including Rails internal metadata and
  Solid Queue tables, is outside this domain-column convention.

The PostgreSQL adapter's `datetime_type` may be configured to `:timestamptz`
for domain migrations, with explicit SQL or column types for local civil
fields. Generated schema dumps remain the source of truth for the resulting
database shape.

### Place and segment time zones

`Place` stores the current/default IANA zone for that place together with
provenance and verification metadata when the place foundation implements
those fields. A place zone is a default, not immutable historical truth.

Each scheduled departure and arrival stores the zone actually used for its
resolution on `TravelSegment`. Resolution must not depend on reading the
current `Place` zone later. This preserves an auditable snapshot and permits a
manual or source-provided override without mutating place data.

Fixed offsets may be preserved as source evidence or snapshots, but an offset
alone is never accepted as the long-term zone identity.

### Resolution boundary

All local civil datetime resolution is owned by one dedicated
`TimeZones::ResolveLocalTime` service backed by the existing TZInfo dependency.
It accepts a local value, an IANA zone, and an explicit resolution policy, and
returns a result containing:

- the resolved UTC instant when one is safely known;
- the applied offset when resolution occurred;
- a resolution status;
- diagnostics suitable for private import/reporting surfaces.

The default policy is conservative:

- exact, valid local times resolve normally;
- ambiguous DST fall-back times remain unresolved unless an authoritative
  source offset/UTC value or an explicit policy disambiguates them;
- invalid DST spring-forward times remain unresolved and are never silently
  shifted;
- missing or unsupported zones remain unresolved;
- a source-provided UTC instant is accepted according to the source contract,
  but is checked against local-plus-zone interpretation and conflicts are
  retained as quality/provenance data rather than hidden.

Parsing a local value must preserve its zone-less civil components until this
service applies the named zone. Generic `Time.parse`, implicit `Time.zone`
conversion, and browser/user timezone conversion are not valid resolution
strategies for imported airport-local schedule values.

Resolution status and segment-level time quality are separate concepts. The
future OpenSpec change that implements this boundary will define the canonical
status values and storage constraints; the ADR intentionally does not turn a
diagnostic vocabulary into a premature schema contract.

### Duration and derived values

Elapsed duration is calculated only by subtracting absolute instants. Local
wall-clock values from different places are never subtracted directly.

Scheduled and actual durations are different facts and must not overwrite each
other. Any persisted duration is a derived/cache value whose source and
recalculation rule are explicit; the authoritative inputs remain the relevant
departure and arrival instants.

### Future and historical data

For a future scheduled event, the source representation is:

```text
published local schedule + segment IANA time zone
```

The UTC instant and offset are derived values and may be recalculated when
tzdata or the source schedule changes. Re-resolution must be explicit and
auditable. Routeprint must not silently rewrite past user history when place
data or timezone rules are corrected.

For historical imports, Routeprint preserves the segment zone snapshot, the
resolved instant, offset evidence, raw source values, and uncertainty. A
current place zone is sufficient as the MVP fallback, but it is not claimed to
be historically perfect.

### Import and privacy boundary

Import flows preserve raw time strings, raw UTC/offset values, source identity,
and raw payloads according to the import architecture. Parsing and resolution
are best-effort per row: an ambiguous, invalid, incomplete, or conflicting row
is diagnosed and reviewable without failing an otherwise valid batch.

Raw import/email data remains private. It must not be exposed through Inertia
props or public profile/share surfaces.

### Display and grouping

Flight departure and arrival are displayed in the corresponding airport-local
time, including the local-date rollover indicator when appropriate. Flight
history grouping uses the origin-local departure date. Browser and user-profile
time zones do not reinterpret airport departure or arrival times.

## Alternatives considered

### Store UTC only

Rejected. UTC is sufficient for ordering and elapsed duration, but loses the
published local schedule and the zone rules needed for faithful display,
future recalculation, and auditability.

### Store local time and a fixed offset only

Rejected. An offset describes one interpretation at one instant and cannot
represent daylight-saving or political rule changes. It is retained only as
evidence alongside the named IANA zone.

### Resolve from the current place zone at read time

Rejected. Place data can be corrected, and historical or manually overridden
segments need the zone used for their own source event.

### Build historical place-zone assignment tables in the MVP

Deferred. Historical airport-zone changes are real, but the table and repair
workflow should be added only when old bulk imports make the additional
maintenance cost justified. The MVP still preserves enough provenance to add
that hardening later.

### Use a user or browser timezone for flight times

Rejected. User/browser zones are suitable for account activity and selected UI
preferences, not for airport-local transportation events.

## Consequences

Positive:

- Cross-zone and date-line durations are computed correctly from instants.
- Airport-local schedule fidelity survives UTC conversion and place-data
  changes.
- Future schedules can be re-resolved without losing the published local
  representation.
- Ambiguous, invalid, partial, and conflicting source data remains visible and
  repairable instead of being silently fabricated.
- The architecture supports manual entry, CSV/App in the Air imports, later
  email/API enrichment, and future live/actual timestamps without a second
  time model.

Costs and constraints:

- Travel segments and import pipelines require more fields and explicit
  diagnostics than a UTC-only model.
- A dedicated resolver and DST/date-line tests are mandatory.
- Exact field names, status enums, repair UI, historical assignments, tzdata
  version tracking, and re-resolution jobs belong to subsequent OpenSpec
  changes, not to this ADR alone.
- Storing raw source data increases privacy obligations and must follow ADR
  0003 and the security baseline.

## Non-goals

- Live flight tracking or real-time operational status.
- A calendar recurrence/timezone engine.
- A complete historical airport-zone database in the MVP.
- Automatic correction of past imported history without an explicit repair
  workflow.
- A public or browser-side raw import payload surface.

## References

- [PostgreSQL date/time types](https://www.postgresql.org/docs/current/datatype-datetime.html)
- [Rails PostgreSQL adapter `datetime_type`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/PostgreSQLAdapter.html)
- [TZInfo timezone behavior](https://msp-greg.github.io/tzinfo/TZInfo/Timezone.html)
- [ADR 0003: Import Architecture](0003-import-architecture.md)
