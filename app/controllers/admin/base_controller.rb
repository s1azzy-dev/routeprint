module Admin
  class BaseController < ApplicationController
    before_action :require_admin!
    around_action :use_request_locale

    private

    def admin_navigation(current:)
      {
        sections: [
          {
            key: "primary",
            items: [
              admin_navigation_item(
                key: "airports",
                icon: "airports",
                label: t("admin.navigation.airports"),
                url: admin_airports_path,
                current: current == "airports"
              )
            ]
          },
          {
            key: "imports",
            label: t("admin.navigation.imports.label"),
            items: [
              admin_navigation_item(
                key: "import_airports",
                icon: "airports",
                label: t("admin.navigation.imports.airports"),
                url: admin_imports_airports_path,
                current: current == "imports/airports"
              ),
              admin_navigation_item(
                key: "import_countries",
                icon: "airports",
                label: t("admin.navigation.imports.countries"),
                url: admin_imports_countries_path,
                current: current == "imports/countries"
              )
            ]
          }
        ]
      }
    end

    def admin_navigation_item(key:, icon:, label:, url:, current:)
      { key:, icon:, label:, url:, current: }
    end

    def require_admin!
      return if current_user&.admin?

      if authenticated?
        redirect_to root_path, alert: t("admin.authorization.required")
      else
        redirect_to sign_in_path, alert: t("auth.sessions.require_authentication")
      end
    end

    def use_request_locale(&action)
      I18n.with_locale(current_user&.locale || I18n.default_locale, &action)
    end
  end
end
