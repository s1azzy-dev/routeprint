module Flights
  # Builds form display values, catalog options and translated validation feedback.
  class FormPresenter
    def initialize(locale:, values:, flight: nil, failure: {})
      @locale = locale
      @flight = flight
      @failure = failure
      defaults = EntryAttributes::FIELDS.index_with { "" }.merge(creation_request_key: "")
      @values = defaults.merge(values).transform_values { |value| value.nil? ? "" : value }
    end

    def as_json(*)
      options = FormOptionsQuery.call(values:)
      {
        copy: translate("flights").except(:errors), values:, formErrors: translated_errors,
        duplicates: Array(failure[:candidates]).map { |candidate| FlightPresenter.new(flight: candidate, locale:).as_json },
        selected: selected_references(options),
        airlinePicker: airline_picker(options[:countries]),
        urls: form_urls,
        editing: flight.present?
      }
    end

    private

    attr_reader :locale, :values, :flight, :failure

    def routes
      Rails.application.routes.url_helpers
    end

    def translate(key, **options)
      I18n.t(key, locale:, **options)
    end

    def form_urls
      {
        index: routes.flights_path, submit: flight ? routes.flight_path(flight) : routes.flights_path,
        airportSearch: routes.search_airports_path, airlineSearch: routes.search_airlines_path,
        airlineSubmit: routes.airlines_path
      }
    end

    def selected_references(options)
      places = options[:places]
      airlines = options[:airlines]
      %i[departure arrival].to_h do |event|
        place = places[values[:"#{event}_place_id"].to_s.downcase]
        [ event, Airports::PickerPresenter.call(place, locale:) ]
      end.merge(%i[marketing operating].to_h do |role|
        airline = airlines[values[:"#{role}_airline_id"].to_s.downcase]
        [ role, airline && airline.system_key.nil? ? Airlines::PickerPresenter.new(
          airline:, flight_date: nil, locale:).as_json : nil ]
      end)
    end

    def airline_picker(countries)
      {
        copy: translate("airlines.picker").deep_transform_keys { |key| key.to_s.camelize(:lower) },
        countries: countries.map { |country| { id: country.id, name: country.name_for(locale) } }
      }
    end

    def translated_errors
      error_fields(failure.fetch(:errors, {})).to_h do |key|
        field = key.to_s.delete_prefix("flight_detail.")
        field = { "departure_place" => "departure_place_id", "arrival_place" => "arrival_place_id" }.fetch(field, field)
        field = "base" unless EntryAttributes::FIELDS.map(&:to_s).include?(field)
        message = if failure[:code] == :submission_conflict
          translate("flights.errors.submission_conflict")
        else
          translate("flights.errors.fields.#{field}", default: translate("flights.errors.invalid"))
        end
        [ field, message ]
      end
    end

    def error_fields(errors)
      errors.to_h.flat_map { |key, messages| messages.is_a?(Hash) ? error_fields(messages) : key }
    end
  end
end
