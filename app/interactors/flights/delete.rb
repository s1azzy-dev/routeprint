module Flights
  # Deliberately deletes one owned flight with its specialization.
  #
  # @example
  #   Flights::Delete.call(input: { user:, flight_id:, confirmed: true })
  # @param input [Hash] trusted user, flight identifier, and explicit confirmation
  class Delete < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:flight_id).filled(:string)
        required(:confirmed).filled(:bool)
      end
    end

    def call
      user = input.fetch(:user)
      flight_id = input.fetch(:flight_id)
      confirmed = input.fetch(:confirmed)
      flight = user.travel_segments.find_by(id: flight_id)
      return fail_with(code: :not_found) unless flight && TravelSegmentPolicy.new(user, flight).destroy?
      return fail_with(code: :validation_error, errors: { base: [ :invalid ] }) unless confirmed == true

      flight.destroy!
      Success()
    end
  end
end
