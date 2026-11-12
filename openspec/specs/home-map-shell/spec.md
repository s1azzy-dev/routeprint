# home-map-shell Specification

## Purpose

Provide the public home page with a full-viewport MapLibre map, application-owned
frontend assets, and cleanup when the React component unmounts. The map shows
each signed-in member's private flight routes.

## Requirements
### Requirement: Home route provides a full-viewport map shell

The public home route SHALL render a full-viewport interactive MapLibre map
inside the Inertia/React page after the frontend entrypoint loads.

#### Scenario: Home page mounts the map

- **WHEN** a browser visits `/` with JavaScript enabled
- **THEN** the `Home/Show` page mounts a MapLibre map container that occupies
  the available viewport

#### Scenario: Map assets are application-owned

- **WHEN** the home page loads MapLibre
- **THEN** the MapLibre JavaScript and CSS are resolved from the application's
  Vite-built dependency assets rather than runtime CDN script or stylesheet
  tags

### Requirement: Home map renders a route line

The home map SHALL draw the visible part of the shorter great-circle arc for
each drawable airport pair in the owner's flight history.

#### Scenario: Initial route line is added after map load

- **GIVEN** the home page has drawable routes
- **WHEN** the map style loads
- **THEN** the map receives a GeoJSON route source and a styled line layer

#### Scenario: A recorded flight is visible on the map

- **GIVEN** the owner has recorded a flight between airports with valid coordinates
- **WHEN** the owner opens the home map
- **THEN** the map draws the arc and fits the initial overview to the extent of the visible route geometry

#### Scenario: Route crosses the antimeridian

- **WHEN** a route crosses the antimeridian within the visible latitude range
- **THEN** its parts meet at the same latitude across adjacent world copies without a line across the center of the map

#### Scenario: Route crosses the Mercator latitude limit

- **WHEN** a route leaves and re-enters the visible Mercator latitude range
- **THEN** both visible sections end at the limit and a gap remains over the hidden arc

#### Scenario: A pair has no stable drawable arc

- **WHEN** coordinates are invalid, coincident, exactly antipodal, or the entire arc is outside the visible latitude range
- **THEN** the map omits the line and the flight remains available in history

#### Scenario: The style or flight data changes

- **WHEN** the style reloads or the home page receives refreshed route data
- **THEN** the map draws the latest routes and counts on the existing map instance

### Requirement: Home map exposes a React-owned reset control

The map shell SHALL expose an accessible React button that returns the map to
its initial view without creating a second map instance.

#### Scenario: User resets the map view

- **WHEN** the user activates the reset-view button
- **THEN** the mounted MapLibre instance receives a camera reset command

### Requirement: Map lifecycle is cleaned up

The map component SHALL remove its native MapLibre instance when it unmounts.

#### Scenario: Home page unmounts

- **WHEN** the map component is unmounted
- **THEN** the MapLibre instance is removed and no map instance remains attached
  to the component container

### Requirement: Personal route data is scoped to the owner

The home map SHALL receive a compact overview of the signed-in owner's complete
flight history, grouped by unordered pairs of airport place identities.

#### Scenario: Owner has flights in both directions

- **GIVEN** the owner has flights between the same airports in both directions
- **WHEN** the home map loads
- **THEN** the owner sees one logical route and one aggregate count label per world copy wherever collision handling permits
- **AND** the response includes only a stable route ID, airport coordinates, and count per pair

#### Scenario: Guest or member has no routes

- **GIVEN** other users have recorded flights
- **WHEN** a guest or a signed-in member without flights visits the home page
- **THEN** the page shows only the basemap with an empty route payload

#### Scenario: Another account has flights

- **WHEN** a signed-in member, including an administrator, visits the home map
- **THEN** other accounts' flights and counts are absent from the response
