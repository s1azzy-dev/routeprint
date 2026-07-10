module Imports
  class RunItem < ApplicationRecord
    STATUSES = %w[queued running succeeded failed cancelled].freeze

    belongs_to :run, class_name: "Imports::Run", inverse_of: :items

    has_many :artifacts, class_name: "Imports::Artifact", foreign_key: :run_item_id, inverse_of: :run_item, dependent: :nullify
    has_many :issues, class_name: "Imports::Issue", foreign_key: :run_item_id, inverse_of: :run_item, dependent: :nullify

    enum :status, STATUSES.index_with(&:itself), prefix: true

    normalizes :item_kind, :item_key, with: ->(value) { value.to_s.strip.presence }

    validates :item_kind, :item_key, presence: true
    validates :status, presence: true, inclusion: { in: STATUSES }
    validates :attempts_count, numericality: { greater_than_or_equal_to: 0 }

    scope :active, -> { where(status: %w[queued running]) }
  end
end
