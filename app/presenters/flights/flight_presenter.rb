module Flights
  # The allowlisted private detail and history response; never serializes models.
  class FlightPresenter
    def initialize(flight:, locale:)
      @flight = flight
      @locale = locale
    end

    def as_json(*)
      {
        id: flight.id, departureDate: flight.departure_date.iso8601,
        arrivalDate: flight.arrival_date&.iso8601,
        departureTime: flight.departure_local_at&.strftime("%H:%M"),
        arrivalTime: flight.arrival_local_at&.strftime("%H:%M"),
        departureAirport: Airports::PickerPresenter.call(flight.departure_place, locale:),
        arrivalAirport: Airports::PickerPresenter.call(flight.arrival_place, locale:),
        marketingAirline: carrier(detail.marketing_airline), operatingAirline: carrier(detail.operating_airline),
        flightNumber: detail.flight_number, marketingDesignator: detail.marketing_designator,
        warnings: %w[departure arrival].filter_map do |event|
          status = flight.public_send("#{event}_resolution")
          I18n.t("flights.unresolved", locale:) if %w[ambiguous nonexistent missing_zone].include?(status)
        end.uniq,
        urls: { show: routes.flight_path(flight), edit: routes.edit_flight_path(flight),
          destroy: routes.flight_path(flight) }
      }
    end

    def form_values
      {
        departure_place_id: flight.departure_place_id, arrival_place_id: flight.arrival_place_id,
        departure_date: flight.departure_date.iso8601, arrival_date: flight.arrival_date&.iso8601,
        departure_time: flight.departure_local_at&.strftime("%H:%M"),
        arrival_time: flight.arrival_local_at&.strftime("%H:%M"),
        marketing_airline_id: detail.marketing_airline_id, operating_airline_id: detail.operating_airline_id,
        flight_number: detail.flight_number
      }
    end

    private

    attr_reader :flight, :locale

    def routes
      Rails.application.routes.url_helpers
    end

    def detail
      flight.flight_detail
    end

    def carrier(airline)
      return unless airline
      return nil if airline.system_key == Airline::UNKNOWN_SYSTEM_KEY

      Airlines::PickerPresenter.new(airline:, flight_date: flight.departure_date, locale:).as_json
    end
  end
end
