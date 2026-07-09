# TODO

This is the ordered queue for known behavior and deferred architecture/tooling
work that is not implemented. It is not a specification and does not authorize
implementation by itself.

Before starting an item:

1. Confirm it still solves a current product or operational problem.
2. Create a Level 2 OpenSpec change, or Level 3 plus an ADR when a durable
   architecture decision is required.
3. Remove the item after the change is implemented and archived.

## P0: Bootstrap And Product Foundation

1. Bootstrap Routeprint harness from Wild Waters process patterns without
   copying business logic.
2. Add authentication/session/password reset foundation.
3. Add Routeprint design shell and protected dashboard.

## P1: Flight History MVP

4. Add places/airports/airlines foundation.
5. Add manual flight history.
6. Add travel map with route lines and statistics.
7. Add CSV import with preview, validation, duplicate candidates, and apply
   flow.
8. Add App in the Air import from sanitized sample export files.
9. Add CSV/JSON export.

## P2: Launch Readiness

10. Add landing/onboarding flow.
11. Add privacy/export/delete-account copy and behavior.
12. Add authentication abuse protection/rate limiting for public auth endpoints.
13. Add mandatory email verification before public launch, email import, or
    OAuth account linking.
14. Add admin import operations visibility.

## P3: Post-MVP Expansion

15. Add additional flight-history imports.
16. Add trips and travel journal grouping.
17. Add email forwarding import.
18. Add OAuth login and account-linking policy only after a separate auth
    OpenSpec change.
19. Add connected accounts for Gmail, Outlook, calendar, TripIt, or similar
    integrations with encrypted external-provider token storage.
20. Add upcoming flights.
21. Evaluate external flight data API for enrichment/live status.
22. Add non-flight transport modes only after explicit product decision.
23. Evaluate PWA/mobile app after web MVP validates usage.
