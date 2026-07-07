# ADR 0003: Import Architecture

## Status

Accepted

## Decision

Routeprint treats imports as a first-class subsystem with import batches/runs,
source records, raw payload preservation, normalized payloads, duplicate
detection, preview/apply, sanitized errors, and retry-safe processing.

## Consequences

- Imports are provenance-aware and idempotent.
- Raw source payloads remain private.
- Source-specific parsers feed a common validation and apply pipeline.
- Domain writes pass through explicit application use cases.
