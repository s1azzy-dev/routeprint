# admin-airport-management Specification

## Purpose
TBD - created by archiving change add-admin-airport-management. Update Purpose after archive.
## Requirements
### Requirement: Admin area is restricted to administrators

The system SHALL expose the admin airport workspace only to authenticated users
whose persisted role is `admin`. The account menu SHALL include an Admin action
only when the server provides an admin URL for the current user.

#### Scenario: Anonymous visitor requests the admin workspace

- **WHEN** an anonymous visitor requests the admin airport index
- **THEN** the visitor is redirected to sign in and no airport data is rendered

#### Scenario: Authenticated member requests the admin workspace

- **WHEN** an authenticated non-admin user requests the admin airport index
- **THEN** the user is redirected to the public home page and no airport data is rendered

#### Scenario: Administrator opens the account menu

- **WHEN** an administrator opens the authenticated account menu outside the admin area
- **THEN** an Admin action is visible and links to the admin airport workspace

### Requirement: Administrator can browse a paginated airport catalog

The system SHALL render a shadcn-based admin workspace with left navigation and a
central airport table. The table SHALL show a bounded page of canonical airport
records and expose previous/next pagination links without exposing raw session
material or unrelated private data.

#### Scenario: Administrator opens the airport index

- **WHEN** an administrator requests the first airport page
- **THEN** the response renders the admin airport Inertia page with airport rows, pagination metadata, and current navigation state

#### Scenario: Administrator requests another page

- **WHEN** an administrator follows a valid airport pagination link
- **THEN** the response renders only that bounded page and preserves the page state in the URL

#### Scenario: Airport catalog is empty

- **WHEN** an administrator opens the airport index with no canonical airports
- **THEN** the workspace renders an accessible empty state and does not render an empty table body as the only feedback

### Requirement: Administrator can update an airport

The system SHALL allow an administrator to edit the airport's canonical name,
municipality, country and region codes, timezone, operational status, IATA code,
and ICAO code. A successful update SHALL persist both the airport and its place
atomically and return the administrator to the airport index with feedback.

#### Scenario: Administrator saves valid airport edits

- **WHEN** an administrator submits valid edits for an existing airport
- **THEN** the place and airport changes are persisted together and the response redirects to the airport index with a success message

#### Scenario: Administrator submits invalid airport edits

- **WHEN** an administrator submits malformed codes or an invalid timezone
- **THEN** no partial changes are persisted and the response returns validation errors to the admin edit form

#### Scenario: Administrator updates an airport with import provenance

- **WHEN** an administrator saves valid edits for an airport linked to an import source record
- **THEN** the canonical airport changes are persisted without deleting or rewriting provenance links

### Requirement: Administrator can delete an airport deliberately

The system SHALL require an explicit confirmation action before deleting an
airport. A successful deletion SHALL remove the canonical airport and place when
the database permits it, while a protected record SHALL return a safe failure
without bypassing referential integrity.

#### Scenario: Administrator confirms deletion of an unlinked airport

- **WHEN** an administrator confirms deletion for an airport with no dependent source links
- **THEN** the airport and its place are deleted and the response redirects to the airport index with a success message

#### Scenario: Administrator attempts to delete a linked airport

- **WHEN** an administrator confirms deletion for an airport referenced by import provenance
- **THEN** the record remains intact and the response redirects to the airport index with an actionable failure message

#### Scenario: Non-admin submits an airport mutation

- **WHEN** an authenticated non-admin user submits an update or delete request for an airport
- **THEN** the request is denied without changing the record

