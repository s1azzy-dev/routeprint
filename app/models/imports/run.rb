module Imports
  class Run < ApplicationRecord
    MODES = %w[full incremental replay retry].freeze
    STATUSES = %w[queued running succeeded partially_failed failed cancelled].freeze

    belongs_to :source, class_name: "Imports::Source", inverse_of: :runs
    belongs_to :retry_of_run, class_name: "Imports::Run", optional: true, inverse_of: :retry_runs
    belongs_to :initiated_by, class_name: "User", foreign_key: :initiated_by_user_id, optional: true

    has_many :retry_runs, class_name: "Imports::Run", foreign_key: :retry_of_run_id, inverse_of: :retry_of_run, dependent: :nullify
    has_many :items, class_name: "Imports::RunItem", foreign_key: :run_id, inverse_of: :run, dependent: :restrict_with_exception
    has_many :source_records, class_name: "Imports::SourceRecord", foreign_key: :last_import_run_id, inverse_of: :last_import_run, dependent: :nullify
    has_many :artifacts, class_name: "Imports::Artifact", foreign_key: :run_id, inverse_of: :run, dependent: :restrict_with_exception
    has_many :snapshots, class_name: "Imports::RecordSnapshot", foreign_key: :run_id, inverse_of: :run, dependent: :restrict_with_exception
    has_many :issues, class_name: "Imports::Issue", foreign_key: :run_id, inverse_of: :run, dependent: :restrict_with_exception

    enum :mode, MODES.index_with(&:itself), prefix: true
    enum :status, STATUSES.index_with(&:itself), prefix: true

    validates :mode, presence: true, inclusion: { in: MODES }
    validates :status, presence: true, inclusion: { in: STATUSES }
    validates :total_item_count, :completed_item_count, :failed_item_count, :issue_count,
      numericality: { greater_than_or_equal_to: 0 }

    scope :active, -> { where(status: %w[queued running]) }
  end
end
