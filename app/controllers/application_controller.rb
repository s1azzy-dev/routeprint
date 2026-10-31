class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  layout "inertia"

  inertia_share do
    {
      app: {
        name: t("routeprint")
      },
      shell: {
        authenticated: authenticated?,
        labels: {
          admin: t("layouts.header.admin"),
          accountMenu: t("layouts.header.account_menu"),
          brandName: t("routeprint"),
          mainPage: t("layouts.header.main_page"),
          flights: t("flights.title", locale: current_user&.locale || I18n.default_locale),
          signIn: t("layouts.header.sign_in"),
          signOut: t("layouts.header.sign_out")
        },
        urls: {
          admin: current_user&.admin? ? admin_root_path : nil,
          home: root_path,
          flights: authenticated? ? flights_path : nil,
          signIn: sign_in_path,
          signOut: sign_out_path
        }
      }
    }
  end

  # Only allow modern browsers supporting webp images, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
