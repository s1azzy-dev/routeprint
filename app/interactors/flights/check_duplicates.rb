module Flights
  # Checks bounded private route/date candidates before an intentional repeat.
  #
  # @example
  #   Flights::CheckDuplicates.call(input: { user:, attributes: })
  # @param input [Hash] current user, normalized segment values, confirmation, optional excluded flight
  class CheckDuplicates < ApplicationInteractor
    option :input
    option :history_query, default: -> { Flights::HistoryQuery }

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:attributes).filled(:hash)
        optional(:confirmed).maybe(:bool)
        optional(:exclude_id).maybe(:string)
        optional(:exclude_request_key).maybe(:string)
      end
    end

    def call
      user = input.fetch(:user)
      attributes = input.fetch(:attributes)
      confirmed = input[:confirmed]
      exclude_id = input[:exclude_id]
      exclude_request_key = input[:exclude_request_key]
      scope = user.travel_segments.where(attributes.slice(:departure_date, :departure_place, :arrival_place))
      scope = scope.where.not(id: exclude_id) if exclude_id
      scope = scope.where.not(creation_request_key: exclude_request_key) if exclude_request_key
      candidates = history_query.preload_references(scope).order(id: :desc).limit(5).to_a
      return Success() if candidates.empty? || ActiveModel::Type::Boolean.new.cast(confirmed)

      Failure(code: :duplicate_candidates, errors: {}, candidates:)
    end
  end
end
