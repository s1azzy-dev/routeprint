module Imports
  # Persists one source record and, for normalized data, its changed snapshot.
  #
  # @example
  #   Imports::PersistSourceRecord.call(input: { source:, run:, record: })
  # @param input [Hash] source, run, record payload, and optional raw phase
  class PersistSourceRecord < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:source).filled(type?: Imports::Source)
        required(:run).filled(type?: Imports::Run)
        required(:record).filled(:hash)
        optional(:phase).filled(:string)
      end
    end

    def call
      source = input.fetch(:source)
      run = input.fetch(:run)
      record = input.fetch(:record)
      return persist_raw_record(source:, run:, record:) if raw_phase?

      persist_normalized_record(source:, run:, record:)
    end

    private

    def raw_phase?
      input.fetch(:phase, "normalized").to_sym == :raw
    end

    def persist_normalized_record(source:, run:, record:)
      now = Time.current
      raw_payload = record.fetch(:raw_payload)
      normalized_payload = record.fetch(:normalized_payload)
      checksum = record[:checksum] || Imports::PayloadDigest.checksum(raw_payload:, normalized_payload:)

      source_record = source.source_records.find_or_initialize_by(
        record_kind: record.fetch(:record_kind),
        external_uid: record.fetch(:external_uid)
      )
      changed = source_record.new_record? || source_record.checksum != checksum
      previous_status = source_record.status

      source_record.assign_attributes(
        status: previous_status == "applied" && !changed ? "applied" : "staged",
        checksum:,
        raw_payload:,
        normalized_payload:,
        last_seen_at: now,
        last_import_run: run
      )
      source_record.first_seen_at ||= now
      source_record.last_changed_at = now if changed

      return fail_with(code: :validation_error, errors: source_record.errors.to_hash) unless source_record.save

      snapshot = if changed
        source_record.snapshots.create!(
          run:,
          checksum:,
          raw_payload:,
          normalized_payload:,
          captured_at: now
        )
      end

      Success(source_record:, snapshot:, changed:)
    rescue ActiveRecord::RecordNotUnique
      retry
    rescue KeyError => error
      fail_with(code: :validation_error, errors: { record: [ error.message ] })
    end

    def persist_raw_record(source:, run:, record:)
      now = Time.current
      source_record = source.source_records.find_or_initialize_by(
        record_kind: record.fetch(:record_kind),
        external_uid: record.fetch(:external_uid)
      )

      if source_record.new_record?
        raw_payload = record.fetch(:raw_payload)
        source_record.assign_attributes(
          status: "staged",
          checksum: Imports::PayloadDigest.checksum(raw_payload:, normalized_payload: {}),
          raw_payload:,
          normalized_payload: {},
          first_seen_at: now,
          last_seen_at: now,
          last_changed_at: now,
          last_import_run: run
        )
      else
        source_record.assign_attributes(
          status: "staged",
          raw_payload: record.fetch(:raw_payload),
          last_seen_at: now,
          last_import_run: run
        )
      end

      return fail_with(code: :validation_error, errors: source_record.errors.to_hash) unless source_record.save

      Success(source_record:, snapshot: nil, changed: source_record.previous_changes.key?("raw_payload"))
    rescue ActiveRecord::RecordNotUnique
      retry
    rescue KeyError => error
      fail_with(code: :validation_error, errors: { record: [ error.message ] })
    end
  end
end
