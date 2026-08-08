require "digest"

module Airlines
  # Creates or reuses an explicitly confirmed global pending airline candidate.
  #
  # @example
  #   Airlines::SubmitPending.call(input: { user:, name: "Example Air", code: "E1", confirmed: true })
  # @param input [Hash] submitter, candidate fields, and explicit confirmation
  class SubmitPending < ApplicationInteractor
    NAME_MAX_LENGTH = 160

    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:name).filled(:string, max_size?: NAME_MAX_LENGTH)
        optional(:code).maybe(:string)
        optional(:country_id).maybe(:string)
        required(:confirmed).filled(:bool)
      end
    end

    def call
      user = input.fetch(:user)
      name = yield normalize_name(input.fetch(:name))
      code_attributes = yield normalize_code(input[:code])
      country = yield resolve_country(input[:country_id])
      yield validate_confirmation(input.fetch(:confirmed))

      fingerprint = pending_fingerprint(name:, code: code_attributes[:code], country:)
      existing = pending_airline(fingerprint)
      return Success(airline: existing, reused: true) if existing

      create_candidate(user:, name:, code_attributes:, country:, fingerprint:)
    rescue ActiveRecord::RecordNotUnique
      existing = pending_airline(fingerprint)
      return Success(airline: existing, reused: true) if existing

      raise
    end

    private

    def normalize_name(value)
      name = value.to_s.squish
      return Success(name) if name.present? && name.length <= NAME_MAX_LENGTH

      fail_with(code: :validation_error, errors: { name: [ "must be filled and at most 160 characters" ] })
    end

    def normalize_code(value)
      code = value.to_s.strip.upcase.presence
      return Success(system: nil, code: nil) unless code
      return Success(system: "iata", code:) if code.match?(/\A[A-Z0-9]{2}\z/)
      return Success(system: "icao", code:) if code.match?(/\A[A-Z]{3}\z/)

      fail_with(code: :validation_error, errors: { code: [ "must be two alphanumeric or three letters" ] })
    end

    def resolve_country(country_id)
      return Success(nil) if country_id.blank?

      country = Country.find_by(id: country_id)
      return Success(country) if country

      fail_with(code: :validation_error, errors: { country_id: [ "not found" ] })
    end

    def validate_confirmation(value)
      confirmed = ActiveModel::Type::Boolean.new.cast(value)
      return Success() if confirmed

      fail_with(code: :validation_error, errors: { confirmed: [ "must be accepted" ] })
    end

    def pending_fingerprint(name:, code:, country:)
      Digest::SHA256.hexdigest(
        [ name.downcase, code, country&.id&.to_s ].join("\u001F")
      )
    end

    def pending_airline(fingerprint)
      Airline.find_by(review_status: "pending", pending_fingerprint: fingerprint)
    end

    def create_candidate(user:, name:, code_attributes:, country:, fingerprint:)
      in_transaction do
        airline = yield persist_airline(name:, country:, fingerprint:)
        yield persist_designator(airline:, **code_attributes)
        yield persist_submission(airline:, user:, name:, code: code_attributes[:code], country:)

        Success(airline:, reused: false)
      end
    end

    def persist_airline(name:, country:, fingerprint:)
      airline = Airline.new(
        name:,
        review_status: "pending",
        operational_status: "unknown",
        record_kind: "catalog",
        country:,
        pending_fingerprint: fingerprint
      )
      return Success(airline) if airline.save

      fail_with(code: :validation_error, errors: airline.errors.to_hash)
    end

    def persist_designator(airline:, system:, code:)
      return Success() unless code

      designator = airline.designators.new(system:, code:)
      return Success(designator) if designator.save

      fail_with(code: :validation_error, errors: designator.errors.to_hash)
    end

    def persist_submission(airline:, user:, name:, code:, country:)
      submission = airline.build_submission(
        submitted_by_user: user,
        submitted_name: name,
        submitted_code: code,
        submitted_country: country
      )
      return Success(submission) if submission.save

      fail_with(code: :validation_error, errors: submission.errors.to_hash)
    end
  end
end
