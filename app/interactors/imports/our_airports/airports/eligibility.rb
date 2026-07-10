module Imports
  module OurAirports
    module Airports
      class Eligibility
        def self.call(normalized)
          new(normalized).call
        end

        def initialize(normalized)
          @normalized = normalized
        end

        def call
          return Dry::Monads::Failure(code: :excluded_facility, errors: { airport_type: [ @normalized.fetch("airport_type") ] }) unless @normalized.fetch("airport_type").in?(Normalizer::FIXED_WING_TYPES)

          Dry::Monads::Success(@normalized)
        end
      end
    end
  end
end
