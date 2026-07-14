module Admin
  # Updates canonical place and airport fields as one admin action.
  #
  # @example
  #   Admin::UpdateAirport.call(input: { airport:, attributes: })
  # @param input [Hash] airport record and permitted editable attributes
  class UpdateAirport < ApplicationInteractor
    option :input

    PLACE_ATTRIBUTES = %i[name municipality_name country_code region_code time_zone].freeze
    AIRPORT_ATTRIBUTES = %i[operational_status iata_code icao_code].freeze

    class ValidationContract < ApplicationContract
      params do
        required(:airport).filled(type?: Airport)
        required(:attributes).hash
      end
    end

    def call
      airport = input.fetch(:airport)
      attributes = input.fetch(:attributes).symbolize_keys

      ApplicationRecord.transaction do
        airport.place.assign_attributes(attributes.slice(*PLACE_ATTRIBUTES))
        airport.assign_attributes(attributes.slice(*AIRPORT_ATTRIBUTES))
        airport.place.save!
        airport.save!
      end

      Success(airport:)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
