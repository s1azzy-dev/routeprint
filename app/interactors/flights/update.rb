module Flights
  # Edits only a current user's flight and keeps unrelated historical evidence.
  #
  # @example
  #   Flights::Update.call(input: { user:, flight_id:, attributes: })
  # @param input [Hash] trusted user, owned flight identifier, and complete form values
  class Update < ApplicationInteractor
    option :input
    option :prepare_entry, default: -> { Flights::PrepareEntry }
    option :duplicates, default: -> { Flights::CheckDuplicates }

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:flight_id).filled(:string)
        required(:attributes).filled(:hash)
      end
    end

    def call
      user = input.fetch(:user)
      flight_id = input.fetch(:flight_id)
      attributes = input.fetch(:attributes).symbolize_keys
      flight = user.travel_segments.find_by(id: flight_id)
      return fail_with(code: :not_found) unless flight && TravelSegmentPolicy.new(user, flight).update?

      in_transaction do
        flight.lock!
        prepared = yield prepare_entry.call(input: { attributes: EntryAttributes.normalize(attributes), flight: })
        yield duplicates.call(input: { user:, attributes: prepared[:segment],
          confirmed: attributes[:confirmed_duplicate], exclude_id: flight.id })
        flight.assign_attributes(prepared[:segment])
        flight.flight_detail.assign_attributes(prepared[:detail])
        return fail_with(code: :validation_error, errors: flight.errors.to_hash) unless flight.save

        Success(flight:)
      end
    end
  end
end
