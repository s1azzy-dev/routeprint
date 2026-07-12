Fix the requested persistence behavior. Use a reversible SQL-forward migration
and matching specs, but never manually edit `db/structure.sql`; generate it
through the documented Rails/Make workflow. Preserve the project's database
and domain-boundary rules.
