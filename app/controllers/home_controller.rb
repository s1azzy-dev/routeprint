class HomeController < ApplicationController
  def show
    no_store
    routes = authenticated? ? Flights::RoutePairsQuery.call(scope: policy_scope(TravelSegment)) : []
    render inertia: "Home/Show", props: { flightRoutes: routes }
  end
end
