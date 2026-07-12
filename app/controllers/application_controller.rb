class ApplicationController < ActionController::Base
  include Authentication

  layout "inertia"

  inertia_share do
    {
      app: {
        name: t("routeprint")
      },
      shell: {
        authenticated: authenticated?,
        labels: {
          accountMenu: t("layouts.header.account_menu"),
          brandName: t("routeprint"),
          signIn: t("layouts.header.sign_in"),
          signOut: t("layouts.header.sign_out")
        },
        urls: {
          home: root_path,
          signIn: sign_in_path,
          signOut: sign_out_path
        }
      }
    }
  end

  # Only allow modern browsers supporting webp images, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
