class ApplicationController < ActionController::Base
  layout "inertia"

  inertia_share do
    {
      app: {
        name: "Routeprint"
      }
    }
  end

  # Only allow modern browsers supporting webp images, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
