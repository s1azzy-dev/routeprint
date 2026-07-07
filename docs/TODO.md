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
12. Add admin import operations visibility.

## P3: Post-MVP Expansion

13. Add additional flight-history imports.
14. Add trips and travel journal grouping.
15. Add email forwarding import.
16. Add upcoming flights.
17. Evaluate external flight data API for enrichment/live status.
18. Add non-flight transport modes only after explicit product decision.
19. Evaluate PWA/mobile app after web MVP validates usage.
