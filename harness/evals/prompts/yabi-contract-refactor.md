Refactor the named yabi interactor to the existing Routeprint convention while
preserving its behavior. Use a real ValidationContract, explicit input flow,
injected collaborators, and a fail-fast pipeline. Add or update focused
interactor specs, then run `make agent-rspec` and `make verify-fast`.
