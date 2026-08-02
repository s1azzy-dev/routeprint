module Imports
  class AirlineSourceLink < ApplicationRecord
    MATCH_STRATEGIES = %w[external_link created_from_source manual].freeze

    belongs_to :source_record, class_name: "Imports::SourceRecord", inverse_of: :airline_source_link
    belongs_to :airline

    normalizes :match_strategy, with: ->(value) { value.to_s.strip.downcase.presence }

    validates :match_strategy, presence: true, inclusion: { in: MATCH_STRATEGIES }
    validates :matched_at, presence: true
    validates :source_record_id, uniqueness: true
    validate :airline_is_not_a_system_placeholder

    private

    def airline_is_not_a_system_placeholder
      return unless airline&.record_kind == "system_placeholder"

      errors.add(:airline, :invalid)
    end
  end
end
