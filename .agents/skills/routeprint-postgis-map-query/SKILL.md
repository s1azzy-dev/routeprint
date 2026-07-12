---
name: routeprint-postgis-map-query
description: Use this skill when changing Routeprint geospatial data, PostGIS-backed airport or route queries, map payloads, travel history queries, geospatial migrations, or index-backed map performance.
---

# Routeprint PostGIS Map Query

## When to use

Use for airport coordinates, route geometry, bounds queries, map data endpoints,
travel history filters, geospatial indexes, PostGIS migrations, and
payload/performance changes in map surfaces.

If the task requires detailed spatial SQL, geometry operations, or migration implementation, also use the global `postgis` skill.

## Read

- `docs/CONTEXT_MAP.md` rows for airports/places, travel segments/flights,
  map/GeoJSON, migrations/PostGIS, or models/domain persistence.
- `docs/FOUNDATIONS.md` data, geospatial, and database boundaries.
- The target query/presenter/controller/model/spec, then one neighboring query or request/system spec.
- `docs/adr/0001-map-and-geospatial-stack.md` only when changing MapLibre,
  route geometry, or map data delivery behavior.
- Recent migrations only when schema or indexes change.

## Do not read by default

- Imports ADRs.
- Auth/security docs unless protected/private/user data enters the payload.
- All migrations or full `db/structure.sql`.
- Frontend files unless the map UI contract changes.

## Procedure

1. Identify whether the change is read-query, payload shape, UI behavior, migration/index, or model persistence.
2. Confirm the flight-first MVP boundary: flights are the only active
   user-facing transport mode unless the user explicitly approved broader mode
   behavior.
3. Keep nearby and bounds logic database-backed and index-aware; do not move spatial filtering into controllers.
4. Keep map payloads lean and product-shaped: identifiers, names, coordinates, status/visibility, and only fields needed by the UI.
5. For schema changes, inspect recent migrations, write explicit `up`/`down`, and never edit `db/structure.sql` by hand.
6. Keep the query or payload contract covered by the relevant request, query, or system spec, then use the agent gate (normally `make agent-verify-fast`); reserve `make verify-fast` for canonical local proof.

## Outputs

```text
Loaded:
Skipped:
Change kind:
Query/index boundary:
Payload shape:
Red test:
Verification:
Performance risk:
Open question:
```

## Token economy

- Start from the context-map row and open only one vertical slice: caller, query/presenter, model, matching spec.
- Use `rg "bounds|airport|route|location|ST_|spatial|map_data|MapLibre"` before opening files.
- Read `db/structure.sql` only for generated-output inspection after Rails tasks.
- Prefer short query/payload summaries over pasting full JSON examples.
