module Imports
  class PersistSourceRecord < ApplicationInteractor
    option :input

    def call
      source = input.fetch(:source)
      run = input.fetch(:run)
      record = input.fetch(:record)
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
  end
end
