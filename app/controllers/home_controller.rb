class HomeController < ApplicationController
  def show
    render inertia: "Home/Show"
  end
end
