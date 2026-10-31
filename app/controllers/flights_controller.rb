class FlightsController < ApplicationController
  include Pagy::Method

  before_action :require_authentication
  around_action :with_member_locale

  def index
    authorize TravelSegment
    pager, flights = pagy(:offset, history_scope, limit: 25)
    render inertia: "Flights/Index", props: {
      copy: flight_copy, flights: flights.map { |flight| present(flight).as_json },
      pagination: { nextUrl: pager.urls_hash[:next], previousUrl: pager.urls_hash[:prev] },
      urls: { new: new_flight_path }
    }
  end

  def show
    flight = owned_flight
    authorize flight
    render inertia: "Flights/Show", props: {
      copy: flight_copy, flight: present(flight).as_json, urls: { index: flights_path }
    }
  end

  def new
    authorize TravelSegment
    render_form(values: { creation_request_key: SecureRandom.uuid })
  end

  def edit
    flight = owned_flight
    authorize flight
    render_form(flight:, values: present(flight).form_values)
  end

  def create
    authorize TravelSegment
    values = flight_params
    result = Flights::Create.call(input: { user: current_user, attributes: values })
    write_response(result, values:)
  end

  def update
    flight = owned_flight
    authorize flight
    values = flight_params
    result = Flights::Update.call(input: { user: current_user, flight_id: flight.id, attributes: values })
    write_response(result, values:, flight:)
  end

  def destroy
    flight = owned_flight
    authorize flight
    result = Flights::Delete.call(input: { user: current_user, flight_id: flight.id,
      confirmed: [ true, "true", "1" ].include?(params[:confirmed]) })
    if result.success?
      redirect_to flights_path, status: :see_other
    else
      redirect_to flight_path(flight), alert: t("flights.delete_confirmation"), status: :see_other
    end
  end

  private

  def with_member_locale(&block)
    I18n.with_locale(current_user&.locale || I18n.default_locale, &block)
  end

  def history_scope
    policy_scope(TravelSegment).with_display_references.order(departure_date: :desc, id: :desc)
  end

  def owned_flight
    history_scope.find(params[:id])
  end

  def present(flight)
    Flights::FlightPresenter.new(flight:, locale: current_user.locale)
  end

  def flight_copy
    t("flights").except(:errors)
  end

  def flight_params
    params.expect(flight: [ *Flights::EntryAttributes::FIELDS, :creation_request_key, :confirmed_duplicate ])
      .to_h.symbolize_keys
  end

  def write_response(result, values:, flight: nil)
    if result.success?
      redirect_to flight_path(result.value![:flight]), status: :see_other
    elsif result.failure[:code] == :not_found
      head :not_found
    else
      render_form(values:, flight:, failure: result.failure, status: :unprocessable_content)
    end
  end

  def render_form(values:, flight: nil, failure: {}, status: :ok)
    defaults = Flights::EntryAttributes::FIELDS.index_with { "" }.merge(creation_request_key: "")
    values = defaults.merge(values).transform_values { |value| value.nil? ? "" : value }
    render inertia: "Flights/Form", props: {
      copy: flight_copy, values:, formErrors: translated_errors(failure),
      duplicates: Array(failure[:candidates]).map { |candidate| present(candidate).as_json },
      selected: selected_references(values),
      airlinePicker: airline_picker,
      urls: { index: flights_path, submit: flight ? flight_path(flight) : flights_path,
        airportSearch: search_airports_path, airlineSearch: search_airlines_path, airlineSubmit: airlines_path },
      editing: flight.present?
    }, status:
  end

  def selected_references(values)
    %i[departure arrival].to_h do |event|
      place = Place.includes(:airport, :place_names).find_by(id: values[:"#{event}_place_id"])
      [ event, Airports::PickerPresenter.call(place, locale: current_user.locale) ]
    end.merge(%i[marketing operating].to_h do |role|
      airline = Airline.includes(:designators, country: :country_names).find_by(id: values[:"#{role}_airline_id"])
      [ role, airline && airline.system_key.nil? ? Airlines::PickerPresenter.new(
        airline:, flight_date: nil, locale: current_user.locale).as_json : nil ]
    end)
  end

  def airline_picker
    {
      copy: t("airlines.picker").deep_transform_keys { |key| key.to_s.camelize(:lower) },
      countries: Country.includes(:country_names).order(:name).limit(500).map do |country|
        { id: country.id, name: country.name_for(current_user.locale) }
      end
    }
  end

  def translated_errors(failure)
    error_fields(failure.fetch(:errors, {})).to_h do |key|
      field = key.to_s.delete_prefix("flight_detail.")
      field = { "departure_place" => "departure_place_id", "arrival_place" => "arrival_place_id" }.fetch(field, field)
      field = "base" unless Flights::EntryAttributes::FIELDS.map(&:to_s).include?(field)
      message = if failure[:code] == :submission_conflict
        t("flights.errors.submission_conflict")
      else
        t("flights.errors.fields.#{field}", default: t("flights.errors.invalid"))
      end
      [ field, message ]
    end
  end

  def error_fields(errors)
    errors.to_h.flat_map { |key, messages| messages.is_a?(Hash) ? error_fields(messages) : key }
  end
end
