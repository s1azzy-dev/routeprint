module Airlines
  # Creates the protected unknown-airline catalog record exactly once.
  #
  # @example
  #   Airlines::BootstrapUnknown.call
  class BootstrapUnknown < ApplicationInteractor
    def call
      airline = Airline.create_or_find_by!(system_key: Airline::UNKNOWN_SYSTEM_KEY) do |record|
        record.assign_attributes(
          name: "Unknown airline",
          review_status: "approved",
          operational_status: "unknown",
          record_kind: "system_placeholder"
        )
      end

      Success(airline)
    rescue ActiveRecord::RecordInvalid => error
      fail_with(code: :validation_error, errors: error.record.errors.to_hash)
    end
  end
end
