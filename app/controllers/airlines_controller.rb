class AirlinesController < ApplicationController
  before_action :require_authentication

  def search
    result = Airlines::Search.call(input: search_input)
    return render_search_failure(result.failure) if result.failure?

    payload = result.value!
    render json: {
      airlines: payload.fetch(:airlines).map { |airline| picker_payload(airline, payload[:flight_date]) }
    }
  end

  def create
    result = Airlines::SubmitPending.call(input: submission_input)
    return render_submission_failure(result.failure) if result.failure?

    payload = result.value!
    render json: {
      airline: picker_payload(payload.fetch(:airline)),
      reused: payload.fetch(:reused)
    }, status: payload.fetch(:reused) ? :ok : :created
  end

  private

  def search_input
    {
      query: params[:query],
      flight_date: params[:flight_date]
    }
  end

  def submission_input
    params.require(:airline)
      .permit(:name, :code, :country_id, :confirmed)
      .to_h
      .symbolize_keys
      .merge(user: current_user)
  end

  def picker_payload(airline, flight_date = nil)
    Airlines::PickerPresenter.new(
      airline:,
      flight_date:,
      locale: current_user.locale
    ).as_json
  end

  def render_search_failure(failure)
    render json: { errors: failure.fetch(:errors) }, status: :unprocessable_content
  end

  alias_method :render_submission_failure, :render_search_failure
end
