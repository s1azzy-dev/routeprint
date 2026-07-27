## Why

Routeprint needs a provider-neutral airline catalog before manual flight history
can attach consistent carrier metadata, search historical airlines, or produce
reliable airline statistics. Public airline codes are useful lookup values but
can be absent, duplicated, changed, or reused, so they cannot be the durable
identity of an airline.

## What Changes

- Add canonical global airlines with independent moderation and operational
  states, plus historical public designators that are not treated as global
  identity.
- Add one protected system airline representing an unknown marketing carrier,
  so future flight persistence can keep a required airline foreign key without
  fabricating user-entered data.
- Import active and historical airlines from Wikidata through the existing
  reference-import boundary, using the Wikidata QID as source identity and
  automatically publishing structurally valid trusted-source records.
- Allow authenticated users to search approved and visibly unverified pending
  airlines, reuse an existing pending candidate, or submit a new global pending
  candidate with a required name and optional code/country metadata.
- Add an administrator-only moderation workspace that can edit, approve, reject,
  or merge pending candidates while retaining submission and review audit
  evidence.
- Extend the protected Imports workspace with airline import history and a
  guarded start action.
- Retain closed airlines for historical selection and use flight-date-compatible
  evidence for future ranking without preventing explicit selection.
- Keep travel segments, flight persistence, map rendering, and flight statistics
  outside this change.

## Capabilities

### New Capabilities

- `airline-reference-catalog`: Provider-neutral airline identity, public
  designators, lifecycle states, the protected unknown-airline record, and
  historical lookup behavior.
- `airline-reference-import`: Idempotent Wikidata ingestion, provenance,
  validation, conflict diagnostics, and source-to-airline linking.
- `airline-catalog-selection`: Authenticated airline search, clearly labelled
  pending results, duplicate-candidate reuse, and global pending submission.
- `admin-airline-moderation`: Protected moderation of pending airlines through
  edit, approve, reject, and merge outcomes with audit evidence.

### Modified Capabilities

- `admin-imports-ui`: Add protected airline import navigation, bounded history,
  and a guarded start action alongside existing reference imports.

## Impact

- Adds airline, airline-designator, import-link, moderation, search, and admin
  persistence/application/UI surfaces.
- Reuses the existing `Imports` orchestration, provenance, job, admin shell,
  authorization, Inertia, and `yabi` boundaries.
- Depends on the country reference catalog for optional airline-country
  association; the airline import must not invent unmatched country records.
- Adds Wikidata as an approved external reference source without adding a
  request-time external API dependency.
- Requires request, interactor, model, import integration, policy, frontend, and
  system coverage, including ambiguity and moderation transitions.

This is a Level 3 change because canonical airline identity, designator history,
trusted-source publication, and the shared moderation lifecycle are durable
cross-cutting architecture decisions. A dedicated ADR is required; observable
behavior and implementation tasks remain in this OpenSpec change.

## Assumptions And Unresolved Questions

- The in-progress country reference catalog lands before airline-country links
  become required by implementation.
- Wikidata source profiling will confirm a bounded query/export shape and the
  exact fields available for operational dates and designator validity.
- No product decision remains open for the catalog and moderation behavior
  described here; source-field gaps must degrade to nullable evidence and
  explicit diagnostics rather than broaden scope.
