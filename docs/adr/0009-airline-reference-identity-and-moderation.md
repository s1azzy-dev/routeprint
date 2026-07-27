# ADR 0009: Airline Reference Identity And Moderation

- Status: Proposed
- Decided: 2026-07-27
- Scope: Global airline identity, public designator history, trusted reference
  ingestion, shared pending submissions, moderation, and the unknown-carrier
  boundary used by future flights.

## Context

Routeprint needs airline metadata for manual and imported historical flights,
selection, and airline statistics. That metadata is important but does not
define whether a flight route occurred: airport endpoints remain the essential
evidence for future map lines and base flight counts.

Airline names and public codes are not durable identifiers. Commercial IATA
designators can be absent or deliberately duplicated, while IATA and ICAO
designators can be changed, withdrawn, and reused. Closed airlines must remain
available because Routeprint imports historical travel. A user may also know an
airline that is missing from the trusted catalog, or may not know the airline at
all.

The existing import architecture already separates provider records and source
identity from canonical domain identity. Routeprint also has a protected admin
shell suitable for a bounded reference-moderation workflow.

## Decision

Routeprint owns one global, provider-neutral `Airline` catalog. Every airline
has a Routeprint UUID; names, IATA/ICAO designators, Wikidata QIDs, and other
provider identifiers never replace it.

Public designators are separate time-aware assignments. A designator records
its system, normalized code, and optional validity evidence. The same
designator may belong to multiple airlines, so `(system, code)` is indexed for
candidate lookup but is not globally unique. Lookup returns candidates and may
rank them by flight date, operational evidence, country, and review state
without prohibiting explicit historical selection.

Review and real-world operation are independent lifecycles. Airlines may be
pending, approved, rejected, or merged while separately active, inactive, or
unknown. Approved and visibly unverified pending records are globally
selectable. Rejected and merged records remain persisted for referential
history but cannot be newly selected. A merge records its approved target and
moves supported references transactionally.

Authenticated users may explicitly submit a missing global airline with a
required name and optional code/country evidence. The initial submission and
submitter are retained as admin-only audit data, not ownership. Exact pending
submissions reuse the existing candidate. Administrators may correct a pending
record while preserving the original submission, then approve, reject, or
merge it.

Wikidata is the first free trusted source. Its QID is the upstream identity.
Structurally valid, unambiguous records publish automatically; invalid or
ambiguous rows retain raw provenance and diagnostics without automatic
code/name merging. Source acquisition, retries, snapshots, source links, and
missing-upstream reconciliation remain governed by ADR 0003. A later paid
IATA/ICAO adapter can link to the same Routeprint airlines without changing
their identity.

One protected approved system record has stable key `unknown_airline`. Future
flight persistence uses it when the marketing carrier is not supplied, allowing
a required airline foreign key without fabricating text or using a hard-coded
database UUID default. Ordinary moderation, merge, deletion, and import actions
cannot mutate the system record.

Ordinary user-facing selection shows the airline name and at most one preferred
code without IATA/ICAO terminology. Admin and diagnostic surfaces retain the
explicit code systems and protected evidence.

## Consequences

- Future flights can use one required marketing-airline foreign key and an
  optional operating-airline foreign key.
- Closed and code-reusing airlines remain usable for historical travel.
- Pending user contributions are shared immediately but visibly unverified.
- Code collisions become an ordinary candidate-selection case rather than a
  database-integrity failure.
- Moderation can repair one global record and later relink every dependent
  flight instead of migrating repeated free-text values.
- The catalog accepts some temporary low-quality pending data and therefore
  requires bounded input, audit, explicit labels, and an admin queue.
- Trusted-source quality and license provenance remain observable and
  replaceable through the existing import boundary.

## Alternatives Considered

### Nullable flight airline plus free-text code

Rejected because codes may be missing or ambiguous and repeated strings would
turn moderation into a later grouping and relinking migration.

### User-owned custom airlines

Rejected because private catalog rows require ownership-aware lookup and create
duplicates that cannot benefit other users. Submission attribution is audit,
not ownership.

### Separate canonical airlines and pending candidates

Rejected because future flights would need alternative foreign keys or a
polymorphic reference. One lifecycle keeps selection, moderation, merge, and
statistics relationally consistent.

### Global uniqueness of airline codes

Rejected because public designators are not eternal or universally unique
identity. A pending user record must also never be able to reserve a legitimate
code and block trusted ingestion.

### Require moderation of every imported airline

Rejected because it would make a trusted bulk catalog unusable and overwhelm
the user-submission queue. Deterministic import validation and provenance are
the publication boundary for the approved Wikidata source.

## References

- [IATA airline and location codes](https://www.iata.org/en/services/codes/)
- [IATA airline code search and controlled duplicates](https://www.iata.org/en/publications/directories/code-search)
- [ICAO three-letter and telephony designators](https://www.icao.int/operational-safety/Designators-and-indicators)
- [Wikidata structured-data licensing](https://www.wikidata.org/wiki/Wikidata:Licensing)
- [ADR 0003: Import Architecture](0003-import-architecture.md)
