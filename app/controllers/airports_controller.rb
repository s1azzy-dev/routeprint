class AirportsController < ApplicationController
  before_action :require_authentication

  def search
    query = params[:query]
    unless query.is_a?(String) && query.strip.length.between?(2, 100)
      return render json: { errors: { query: [ t("flights.errors.invalid") ] } }, status: :unprocessable_content
    end

    places = Airports::PickerSearch.call(query: query.strip, locale: current_user.locale)
    render json: { airports: places.map { |place| Airports::PickerPresenter.call(place, locale: current_user.locale) } }
  end
end
