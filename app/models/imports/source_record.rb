module Imports
  class SourceRecord < ApplicationRecord
    STATUSES = %w[staged applied unresolved missing_upstream].freeze

    belongs_to :source, class_name: "Imports::Source", inverse_of: :source_records
    belongs_to :last_import_run, class_name: "Imports::Run", optional: true, inverse_of: :source_records

    has_many :snapshots, class_name: "Imports::RecordSnapshot", foreign_key: :source_record_id, inverse_of: :source_record, dependent: :restrict_with_exception
    has_many :issues, class_name: "Imports::Issue", foreign_key: :source_record_id, inverse_of: :source_record, dependent: :nullify
    has_one :airport_source_link, class_name: "Imports::AirportSourceLink", foreign_key: :source_record_id, inverse_of: :source_record, dependent: :restrict_with_exception

    enum :status, STATUSES.index_with(&:itself), prefix: true

    normalizes :record_kind, :external_uid, with: ->(value) { value.to_s.strip.presence }

    validates :record_kind, :external_uid, :checksum, presence: true
    validates :status, presence: true, inclusion: { in: STATUSES }
  end
end
