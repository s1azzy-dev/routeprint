module Imports
  class AirportSourceLink < ApplicationRecord
    MATCH_STRATEGIES = %w[external_link unambiguous_match created_from_source manual].freeze

    belongs_to :source_record, class_name: "Imports::SourceRecord", inverse_of: :airport_source_link
    belongs_to :airport, class_name: "Airport", foreign_key: :airport_place_id, primary_key: :place_id, inverse_of: :airport_source_links

    normalizes :match_strategy, with: ->(value) { value.to_s.strip.presence }

    validates :match_strategy, presence: true, inclusion: { in: MATCH_STRATEGIES }
    validates :confidence, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :matched_at, presence: true
  end
end
