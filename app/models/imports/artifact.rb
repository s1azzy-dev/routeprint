module Imports
  class Artifact < ApplicationRecord
    KINDS = %w[source_dump raw_snapshot derived].freeze

    belongs_to :run, class_name: "Imports::Run", inverse_of: :artifacts
    belongs_to :run_item, class_name: "Imports::RunItem", optional: true, inverse_of: :artifacts

    has_one_attached :file

    normalizes :kind, :sha256, with: ->(value) { value.to_s.strip.presence }

    validates :kind, presence: true, inclusion: { in: KINDS }
    validates :sha256, :captured_at, presence: true
  end
end
