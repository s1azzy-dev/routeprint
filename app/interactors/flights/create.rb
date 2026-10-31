module Flights
  # Creates an owned flight, preserving one record for retries of the same form.
  #
  # @example
  #   Flights::Create.call(input: { user:, attributes: })
  # @param input [Hash] trusted current user and complete form attributes
  class Create < ApplicationInteractor
    option :input
    option :prepare_entry, default: -> { Flights::PrepareEntry }
    option :duplicates, default: -> { Flights::CheckDuplicates }

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:attributes).filled(:hash)
      end
    end

    def call
      user = input.fetch(:user)
      attributes = input.fetch(:attributes).symbolize_keys
      key = attributes[:creation_request_key].to_s
      return fail_with(code: :not_found) unless TravelSegmentPolicy.new(user, TravelSegment).create?
      return fail_with(code: :validation_error, errors: { base: [ :invalid ] }) unless key.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

      digest = EntryAttributes.digest(attributes)
      existing = user.travel_segments.find_by(creation_request_key: key)
      return replay(existing, digest) if existing

      prepared = yield prepare_entry.call(input: { attributes: EntryAttributes.normalize(attributes) })
      yield duplicates.call(input: { user:, attributes: prepared[:segment],
        confirmed: attributes[:confirmed_duplicate], exclude_request_key: key })
      persist(user:, key:, digest:, prepared:)
    rescue ActiveRecord::RecordNotUnique
      existing = user.travel_segments.find_by(creation_request_key: key)
      raise unless existing

      replay(existing, digest)
    end

    private

    def replay(flight, digest)
      return Success(flight:) if flight.creation_digest == digest

      fail_with(code: :submission_conflict, errors: { base: [ :submission_conflict ] })
    end

    def persist(user:, key:, digest:, prepared:)
      in_transaction do
        flight = user.travel_segments.new(prepared[:segment].merge(creation_request_key: key, creation_digest: digest))
        flight.build_flight_detail(prepared[:detail])
        return fail_with(code: :validation_error, errors: flight.errors.to_hash) unless flight.save

        Success(flight:)
      end
    end
  end
end
