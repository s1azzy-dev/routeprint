class HomeController < ApplicationController
  def show
    render inertia: "Home/Show", props: {
      appName: "Routeprint"
    }
  end
end
