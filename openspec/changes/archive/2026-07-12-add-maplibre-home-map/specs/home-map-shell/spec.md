## ADDED Requirements

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

The map SHALL render a visible GeoJSON `LineString` through an application-owned
MapLibre source and line layer.

#### Scenario: Initial route line is added after map load

- **WHEN** the MapLibre map emits its load event
- **THEN** the map receives a GeoJSON route source and a styled line layer

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
