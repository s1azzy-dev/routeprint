module Flights
  # Relinks flight references inside a caller-owned catalog moderation transaction.
  #
  # @example
  #   Flights::RelinkCarrier.call(input: { actor:, source:, target: })
  # @param input [Hash] admin actor and source/approved-target carrier records
  class RelinkCarrier < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:actor).filled(type?: User)
        required(:source).filled(type?: Airline)
        required(:target).filled(type?: Airline)
      end
    end

    def call
      actor = input.fetch(:actor)
      source = input.fetch(:source)
      target = input.fetch(:target)
      return fail_with(code: :not_authorized) unless actor.active? && actor.admin?

      in_transaction do
        Airline.where(id: [ source.id, target.id ]).order(:id).lock.load
        source.reload
        target.reload
        yield validate_carriers(source:, target:)
        relink(source:, target:)
        Success()
      end
    end

    private

    def validate_carriers(source:, target:)
      valid = source.id != target.id && source.record_kind == "catalog" &&
        target.record_kind == "catalog" && target.review_status == "approved"
      return Success() if valid

      fail_with(code: :validation_error, errors: { target: [ :invalid ] })
    end

    def relink(source:, target:)
      %i[marketing_airline_id operating_airline_id].each do |field|
        FlightDetail.where(field => source.id).update_all(field => target.id, updated_at: Time.current)
      end
    end
  end
end
