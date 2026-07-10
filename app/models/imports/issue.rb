module Imports
  class Issue < ApplicationRecord
    STAGES = %w[acquire parse normalize match apply].freeze
    SEVERITIES = %w[warning error].freeze
    STATUSES = %w[open resolved ignored].freeze

    belongs_to :run, class_name: "Imports::Run", inverse_of: :issues
    belongs_to :run_item, class_name: "Imports::RunItem", optional: true, inverse_of: :issues
    belongs_to :source_record, class_name: "Imports::SourceRecord", optional: true, inverse_of: :issues

    enum :severity, SEVERITIES.index_with(&:itself), prefix: true
    enum :status, STATUSES.index_with(&:itself), prefix: true

    normalizes :stage, :code, with: ->(value) { value.to_s.strip.presence }

    validates :stage, presence: true, inclusion: { in: STAGES }
    validates :code, :message, presence: true
    validates :severity, presence: true, inclusion: { in: SEVERITIES }
    validates :status, presence: true, inclusion: { in: STATUSES }
  end
end
