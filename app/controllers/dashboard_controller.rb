class DashboardController < ApplicationController
  before_action :require_authentication

  def show
    render inertia: "Dashboard/Show", props: {
      copy: {
        email: current_user.primary_email,
        heading: t("dashboard.heading")
      }
    }
  end
end
