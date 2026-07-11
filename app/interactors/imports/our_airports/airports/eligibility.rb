module Imports
  module OurAirports
    module Airports
      # Checks whether a normalized OurAirports facility belongs in the catalog.
      class Eligibility
        # Checks a normalized facility payload.
        #
        # @param normalized [Hash] normalized airport payload
        # @return [Dry::Monads::Result] eligible payload or an exclusion failure
        def self.call(normalized)
          new(normalized).call
        end

        # Builds an eligibility checker for a normalized payload.
        #
        # @param normalized [Hash] normalized airport payload
        def initialize(normalized)
          @normalized = normalized
        end

        # Returns success for facilities in the fixed-wing catalog scope.
        #
        # @return [Dry::Monads::Result] eligibility result
        def call
          return Dry::Monads::Failure(code: :excluded_facility, errors: { airport_type: [ @normalized.fetch("airport_type") ] }) unless @normalized.fetch("airport_type").in?(Normalizer::FIXED_WING_TYPES)

          Dry::Monads::Success(@normalized)
        end
      end
    end
  end
end
