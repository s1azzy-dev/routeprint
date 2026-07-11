# TODO

This is the ordered queue for known behavior and deferred architecture/tooling
work that is not implemented. It is not a specification and does not authorize
implementation by itself.

Before starting an item:

1. Confirm it still solves a current product or operational problem.
2. Create a Level 2 OpenSpec change, or Level 3 plus an ADR when a durable
   architecture decision is required.
3. Remove the item after the change is implemented and archived.

## P1: Flight History MVP

1. Add manual flight history.
2. Add travel map with route lines and statistics.
3. Add CSV import with preview, validation, duplicate candidates, and apply
   flow.
4. Add App in the Air import from sanitized sample export files.
5. Add CSV/JSON export.

## P2: Launch Readiness

6. Add landing/onboarding flow.
7. Add privacy/export/delete-account copy and behavior.
8. Add authentication abuse protection/rate limiting for public auth endpoints.
9. Add mandatory email verification before public launch, email import, or
   OAuth account linking.
10. Add admin import operations visibility.

## P3: Post-MVP Expansion

11. Add additional flight-history imports.
12. Add trips and travel journal grouping.
13. Add email forwarding import.
14. Add OAuth login and account-linking policy only after a separate auth
    OpenSpec change.
15. Add connected accounts for Gmail, Outlook, calendar, TripIt, or similar
    integrations with encrypted external-provider token storage.
16. Add upcoming flights.
17. Evaluate external flight data API for enrichment/live status.
18. Add non-flight transport modes only after explicit product decision.
19. Evaluate PWA/mobile app after web MVP validates usage.
