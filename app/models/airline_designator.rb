class AirlineDesignator < ApplicationRecord
  SYSTEMS = %w[iata icao].freeze

  belongs_to :airline

  normalizes :system, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :code, with: ->(value) { value.to_s.strip.upcase.presence }

  validates :system, presence: true, inclusion: { in: SYSTEMS }
  validates :code, presence: true, uniqueness: { scope: %i[airline_id system], case_sensitive: false }
  validates :code, format: { with: /\A[A-Z0-9]{2}\z/ }, if: -> { system == "iata" }
  validates :code, format: { with: /\A[A-Z]{3}\z/ }, if: -> { system == "icao" }
  validate :validity_range_is_ordered
  validate :airline_is_not_a_system_placeholder

  private

  def validity_range_is_ordered
    return if valid_from.nil? || valid_until.nil? || valid_from <= valid_until

    errors.add(:valid_until, :invalid)
  end

  def airline_is_not_a_system_placeholder
    return unless airline&.record_kind == "system_placeholder"

    errors.add(:airline, :invalid)
  end
end
