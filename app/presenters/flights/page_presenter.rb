module Flights
  # Builds the allowlisted history and detail page props.
  class PagePresenter
    def initialize(locale:)
      @locale = locale
    end

    def index(flights:, pager:)
      {
        copy: copy, flights: flights.map { |flight| present(flight) },
        pagination: { nextUrl: pager.urls_hash[:next], previousUrl: pager.urls_hash[:prev] },
        urls: { new: routes.new_flight_path }
      }
    end

    def show(flight:)
      { copy: copy, flight: present(flight), urls: { index: routes.flights_path } }
    end

    private

    attr_reader :locale

    def routes
      Rails.application.routes.url_helpers
    end

    def copy
      I18n.t("flights", locale:).except(:errors)
    end

    def present(flight)
      FlightPresenter.new(flight:, locale:).as_json
    end
  end
end
