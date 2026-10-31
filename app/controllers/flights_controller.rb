class FlightsController < ApplicationController
  include Pagy::Method

  before_action :require_authentication
  around_action :with_member_locale

  def index
    authorize TravelSegment
    pager, flights = pagy(:offset, history_scope, limit: 25)
    render inertia: "Flights/Index", props: page_presenter.index(flights:, pager:)
  end

  def show
    flight = owned_flight
    authorize flight
    render inertia: "Flights/Show", props: page_presenter.show(flight:)
  end

  def new
    authorize TravelSegment
    render_form(values: { creation_request_key: SecureRandom.uuid })
  end

  def edit
    flight = owned_flight
    authorize flight
    render_form(flight:, values: Flights::FlightPresenter.new(flight:, locale: current_user.locale).form_values)
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
    Flights::HistoryQuery.call(scope: policy_scope(TravelSegment))
  end

  def owned_flight
    history_scope.find(params[:id])
  end

  def page_presenter
    Flights::PagePresenter.new(locale: current_user.locale)
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
    presenter = Flights::FormPresenter.new(locale: current_user.locale, values:, flight:, failure:)
    render inertia: "Flights/Form", props: presenter.as_json, status:
  end
end
