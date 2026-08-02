module Airlines
  # Resolves the protected airline used when a marketing carrier is unknown.
  #
  # @example
  #   Airlines::ResolveUnknown.call
  class ResolveUnknown < ApplicationInteractor
    def call
      airline = Airline.find_by(system_key: Airline::UNKNOWN_SYSTEM_KEY)
      return Success(airline) if airline

      fail_with(code: :unknown_airline_missing)
    end
  end
end
