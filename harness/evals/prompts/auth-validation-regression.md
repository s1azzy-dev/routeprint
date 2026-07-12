Fix the narrow authentication validation regression described by the nearby
spec. Add or adjust the request/model example first, preserve authorization and
CSRF behavior, and use the Routeprint auth security skill. Run the focused
RSpec command through `make agent-rspec`, then the required verification gates.
