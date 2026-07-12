## 1. Dependency and frontend proof

- [x] 1.1 Add exact `maplibre-gl` runtime dependency and regenerate `package-lock.json` through the project frontend install target.
- [x] 1.2 Extend the Home/Map frontend tests with mocked MapLibre assertions for initialization, line source/layer setup, reset control, and cleanup; run the focused test red before production implementation.

## 2. Map component and page

- [x] 2.1 Implement the feature-owned `RouteMap` component with a container ref, native MapLibre ref, local CSS import, demo style, navigation control, and idempotent cleanup.
- [x] 2.2 Add the local GeoJSON `LineString` source and styled line layer after the map load event.
- [x] 2.3 Add the React-owned reset-view control and replace the Home placeholder with a full-viewport map composition while preserving the Inertia page contract.
- [x] 2.4 Run focused frontend tests green and correct formatting, strict types, and lint findings.

## 3. Verification and handoff

- [x] 3.1 Run the Home request spec and strict OpenSpec validation.
- [x] 3.2 Run the applicable frontend/fast verification gate and inspect the production build for the local MapLibre asset.
- [x] 3.3 Update `CHANGES.md` and the README runtime foundation if the completed map shell is retained as current runtime behavior; leave the deferred full travel-map TODO until its data and statistics slice exists.
- [x] 3.4 Verify the implementation against this change, then archive the completed OpenSpec change.
