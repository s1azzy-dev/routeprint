Make the requested auth-form UI change. Keep Rails-owned URLs and security
decisions intact, add component/request/browser-level coverage appropriate to
the behavior, and verify the frontend through the project's agent Make target
and `make verify-fast`. Do not add a dependency for a visual-only change.
