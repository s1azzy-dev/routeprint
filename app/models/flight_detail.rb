class FlightDetail < ApplicationRecord
  belongs_to :travel_segment, inverse_of: :flight_detail
  belongs_to :marketing_airline, class_name: "Airline"
  belongs_to :operating_airline, class_name: "Airline", optional: true

  normalizes :flight_number, with: ->(value) { value.to_s.strip.upcase.presence }
  validates :flight_number, format: { with: /\A[A-Z0-9]{1,16}\z/ }, allow_nil: true
end
