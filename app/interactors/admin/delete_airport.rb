module Admin
  # Deletes an airport and its canonical place when no provenance blocks removal.
  #
  # @example
  #   Admin::DeleteAirport.call(input: { airport: })
  # @param input [Hash] airport record to delete
  class DeleteAirport < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:airport).filled(type?: Airport)
      end
    end

    def call
      airport = input.fetch(:airport)
      airport.place.destroy!

      Success(airport:)
    rescue ActiveRecord::DeleteRestrictionError => error
      fail_with(code: :delete_restricted, errors: { base: [ error.message ] })
    end
  end
end
