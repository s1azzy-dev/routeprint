## Context

Routeprint already has provider-neutral airport persistence, a durable reference
import subsystem, protected import operations, and an in-progress country
catalog. It has no airline persistence or flight records yet. The airline
foundation must therefore establish one global catalog that can be populated by
a trusted source, extended by authenticated users, moderated by administrators,
and later referenced by private flight history.

Airline names and public designators are not durable identity. An airline may
have no IATA designator, may have separate IATA and ICAO designators, may stop
operating, or may share/reuse a public code. Routeprint must also support a
flight whose carrier is genuinely unknown without making the future flight
foreign key nullable.

The existing import boundary in ADR 0003 remains authoritative for acquisition,
raw artifacts, source records, snapshots, runs, diagnostics, and source/domain
links. The in-progress country catalog supplies an optional canonical country
association. User-submitted airline data is global reference input, not
user-owned travel data, but the submitter and moderator remain private audit
metadata.

## Goals / Non-Goals

**Goals:**

- Persist provider-neutral airlines and their time-bounded public designators.
- Keep review state independent from real-world operational state.
- Preserve closed airlines and historical code assignments.
- Provide exactly one protected unknown-airline record for future required
  marketing-airline references.
- Populate the catalog idempotently from a trusted Wikidata snapshot using QID
  source identity.
- Let authenticated users search approved and clearly marked pending entries,
  reuse a matching pending candidate, and explicitly submit a missing candidate.
- Let administrators edit and resolve pending candidates through approve,
  reject, and merge outcomes.
- Keep user-facing airline selection understandable without exposing IATA/ICAO
  terminology by default.

**Non-Goals:**

- Travel-segment or flight persistence.
- Map routes, airline statistics, schedules, live status, aircraft, alliances,
  loyalty programmes, ticketing, or accounting-prefix data.
- Automatic identity matching by airline name or public code.
- A generic moderation framework or a separate ETL service.
- Public anonymous catalog mutation.
- Full historical certainty when Wikidata lacks operating or designator dates.

## Decisions

### 1. Use one global `Airline` lifecycle

`airlines` stores imported, administrator-created, user-submitted, and one
system-placeholder record. It does not introduce user-owned airline rows.

Review state is independent from operational state:

- review: `pending`, `approved`, `rejected`, or `merged`;
- operation: `active`, `inactive`, or `unknown`;
- record kind: ordinary catalog record or protected system placeholder.

Pending records are global and selectable by authenticated users with an
unverified label. Approved records are canonical catalog choices. Rejected and
merged records remain persisted for referential history but are not selectable.
A merged record points to its approved target.

The database owns durable structure: UUID identity, required columns, foreign
keys, one protected system key, and indexes. Application interactors own
allowed transitions, protection of the system row, text normalization, review
vocabularies, and merge orchestration.

Alternative: keep pending rows in a separate candidates table. Rejected because
future flights would need two alternative foreign keys or a polymorphic
reference, complicating every list, statistic, and merge.

Alternative: store unresolved carrier text on each flight. Rejected because it
duplicates candidates across flights and turns moderation into a later
data-migration workflow.

### 2. Store designators as assignments, not airline identity

`airline_designators` belongs to an airline and records:

- designator system (`iata` or `icao`);
- normalized code;
- nullable validity start and end dates;
- whether the source identifies a controlled duplicate;
- source-derived or moderator-managed evidence where applicable.

The same `(system, code)` may belong to multiple airlines. A database uniqueness
boundary prevents an identical code row from being duplicated within one
airline, but there is no global unique code index. Lookup uses a non-unique
index on system and code and must return candidates rather than assume one
result.

The ordinary picker displays one preferred code: IATA when available for the
relevant date, otherwise ICAO, otherwise no code. It does not label those
standards. Admin and diagnostics surfaces show both systems explicitly.

Alternative: put one generic `airline_code` on `airlines`. Rejected because it
cannot distinguish standards, validity, multiple assignments, or legitimate
collisions.

### 3. Protect a real system placeholder instead of using nullable flight data

One airline has stable `system_key = unknown_airline`, approved review state,
unknown operational state, and system-placeholder kind. It is created by an
idempotent application-owned bootstrap path and protected from edit, moderation,
merge, deletion, and import updates.

Future flight interactors resolve this row when no marketing airline is
selected. A future `marketing_airline_id` can therefore be `NOT NULL` with a
foreign key. The database column must not use a hard-coded UUID default;
application orchestration resolves the stable key explicitly.

Alternative: make the future foreign key nullable. Rejected by the confirmed
product decision to make the relational structure complete.

### 4. Make user submissions global, explicit, and auditable

Authenticated search covers normalized airline names and both designator
systems. Results rank approved before pending, then apply exact-match,
flight-date compatibility, activity, and display-name ordering. Closed airlines
remain selectable, and ranking never forbids an explicit selection.

A missing airline is created only through an explicit confirmation action. Name
is required; one generic optional code field and country are optional. The
application classifies a two-character alphanumeric value as IATA and a
three-letter value as ICAO, while the moderator can correct the result.

Before creation, exact normalized matches among approved or pending records are
returned. A matching pending record is reused. A user may confirm creation of a
distinct candidate despite a shared public code. A deterministic submission
fingerprint may have a partial unique index for open pending submissions; that
index prevents duplicate requests and does not assert airline identity.

The initial submission is retained as immutable audit evidence with an optional
submitter foreign key using `ON DELETE SET NULL`. It never defines ownership,
visibility, or authorization.

Alternative: hide pending records from other users. Rejected because shared
visibility reduces duplicate submissions and the product accepts visibly
unverified catalog choices.

### 5. Moderate through explicit fail-fast actions

Admin authorization uses the existing protected admin boundary. The moderation
workspace lists bounded pending records and exposes four explicit actions:

- edit candidate fields while preserving the original submission;
- approve the candidate;
- reject it without deleting it;
- merge it into an approved target.

Merge is transactional: it moves current domain/source references known to the
schema, records the target, and marks the source merged. The future manual-flight
change adds flight-reference relinking while preserving the flight's historical
marketing designator snapshot. A failed reference move rolls back the entire
merge.

Rejected records remain readable only through authorized existing domain
references and admin history; they cannot be selected for new records. Editing
a future flight that references one must require a replacement.

Review metadata records the moderator, review time, and outcome. This change
does not add reopening or multi-stage review.

### 6. Import a versioned Wikidata snapshot through ADR 0003

One `wikidata_airlines` import source owns a versioned query/export definition.
A full run captures the response as a private raw artifact, persists QID-backed
source records, normalizes names, countries, designators, operating evidence,
and validity evidence, and applies accepted records through an airline
interactor.

Source profiling fixed version 1 as a SPARQL-results JSON projection over
direct `instance of: airline` records (`P31 = Q46970`), without subclass
closure. It emits one identity/evidence row per QID and non-deprecated country,
inception, dissolution, IATA, or ICAO statement so repeated claims do not form
a Cartesian product. Country evidence includes both the Wikidata country QID
and any available ISO 3166-1 alpha-2 value (`P297`). An English label is
required for trusted automatic publication; a row without one remains raw
diagnostic evidence. All other fields remain optional.

Acquisition pages the direct-instance set with a server-defined maximum page
size and a validated QID cursor. Each query selects QIDs whose canonical entity
URI sorts after the previous page's final QID, then returns all evidence rows
for that bounded QID set. Page responses are captured as separate private raw
artifacts under one run item. The importer stops only after a short or empty
page, rejects invalid or non-advancing cursors, and caps the number of pages so
upstream drift or a malformed response cannot create an unbounded request loop.
The cursor is acquisition state, never canonical airline identity.

Wikidata time values carry explicit precision. The importer retains inception
and dissolution values and precision in source evidence; those values determine
operational state but do not add canonical airline date columns. A concrete past
dissolution statement can establish inactive operation, but a missing
dissolution statement does not establish active operation and therefore
normalizes to unknown unless stronger evidence is introduced through a reviewed
source-contract change. Designator validity qualifiers are sparse: only day
precision (`11`) may populate canonical `valid_from` or `valid_until`; month
(`10`), year (`9`), unknown, and unsupported precision stay nullable
canonically.

QID is the only upstream identity. Names and designators are match candidates,
never import keys. A new structurally valid unambiguous QID is published as an
approved trusted-source airline. A linked QID updates only source-governed
catalog fields. Missing optional dates or country evidence remains nullable.

An unlinked incoming row that collides ambiguously with existing approved or
pending records is retained and diagnosed without an automatic merge. Invalid
records fail after the raw stage. A record missing from a later complete
snapshot is marked missing upstream; its canonical airline is not deleted or
made unreferenceable.

The import follows existing at-least-once, fail-fast item semantics and never
runs during a user search or flight request.

Alternative: OpenFlights. Rejected because its published airline snapshot and
activity data are stale for this historical catalog and its share-alike
licensing adds an avoidable distribution constraint.

Alternative: paid IATA/ICAO data for MVP. Deferred. Their future adapters can
link to the same canonical airline without changing Routeprint identity.

### 7. Extend existing admin and search patterns

The Imports navigation gains an Airlines page with newest-first paginated run
history and the existing guarded start behavior. The airline moderation page
uses the current admin shell and standard shadcn table/form primitives.

Authenticated airline lookup is bounded and indexed. It returns only the
minimal display shape: Routeprint identifier, name, preferred code, localized
country display data when available, operational label when exceptional, and
pending label when applicable. Submission audit, raw import data, source
payloads, review notes, and internal matching evidence never enter ordinary
Inertia props.

No PostGIS query or geometry is introduced.

### 8. Promote the durable boundary to an ADR

A new ADR records canonical airline identity, non-unique/time-varying
designators, shared pending moderation, trusted-source publication, and the
unknown-airline placeholder. OpenSpec retains feature behavior and tasks.

## Risks / Trade-offs

- [A user submits abusive or meaningless global text] → Require authentication,
  bounded normalized input, explicit confirmation, a visible pending badge, and
  an admin moderation queue; preserve submitter audit without making it
  ownership.
- [A pending row squats a legitimate public code] → Never make public codes
  globally unique and never let a pending row block a QID-backed import solely
  by code.
- [Two real airlines share or reuse a designator] → Return candidate collections,
  show name/country/status, use date-compatible ranking, and never auto-merge by
  code.
- [Wikidata data is incomplete or wrong] → Preserve the raw snapshot and QID
  provenance, validate deterministic structure, diagnose ambiguity, and permit
  later source replacement without changing canonical IDs.
- [A merge partially moves references] → Perform merge and all known reference
  updates in one transaction and keep the source row when the transaction fails.
- [Country catalog is incomplete] → Keep airline country optional and diagnose
  unmatched source evidence rather than creating countries implicitly.
- [Search leaks admin/import evidence] → Return an allowlisted picker payload and
  keep submission, moderation, and raw-source data in protected surfaces.
- [Catalog growth causes slow lookup] → Index normalized name and designator
  lookup paths, bound results, and cover query count/ordering in integration
  specs.

## Migration Plan

1. Finish or rebase onto the country reference catalog required for optional
   country links.
2. Add additive airline, designator, submission-audit, and source-link
   persistence plus the protected unknown-airline bootstrap.
3. Add model/interactor/search coverage and verify the system record is
   idempotent and immutable through ordinary actions.
4. Register the Wikidata source, run one staged fixture-backed import, and
   verify idempotency, ambiguity, and missing-upstream behavior.
5. Add protected import and moderation UI plus authenticated selection and
   submission behavior.
6. Deploy additively, run the first full import, inspect diagnostics, and make
   the catalog available to the later manual-flight change.

Rollback disables selection/import entrypoints and removes additive tables only
when no later flight foreign keys exist. After flights reference airlines,
rollback must preserve the catalog or first migrate those references; the
unknown-airline row is never deleted independently.

## Open Questions

None for the version 1 source shape. Missing or coarse evidence remains
nullable and does not reopen product scope.
