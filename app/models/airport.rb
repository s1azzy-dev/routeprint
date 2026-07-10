class Airport < ApplicationRecord
  OPERATIONAL_STATUSES = %w[active closed unknown].freeze

  belongs_to :place
  has_many :airport_source_links,
    class_name: "Imports::AirportSourceLink",
    foreign_key: :airport_place_id,
    primary_key: :place_id,
    inverse_of: :airport,
    dependent: :restrict_with_exception

  normalizes :operational_status, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :iata_code, with: ->(value) { value.to_s.strip.upcase.presence }
  normalizes :icao_code, with: ->(value) { value.to_s.strip.upcase.presence }

  validates :operational_status, presence: true, inclusion: { in: OPERATIONAL_STATUSES }
  validates :iata_code, format: { with: /\A[A-Z]{3}\z/ }, allow_nil: true
  validates :icao_code, format: { with: /\A[A-Z]{4}\z/ }, allow_nil: true
end
