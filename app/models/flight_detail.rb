class FlightDetail < ApplicationRecord
  belongs_to :travel_segment, inverse_of: :flight_detail
  belongs_to :marketing_airline, class_name: "Airline"
  belongs_to :operating_airline, class_name: "Airline", optional: true
end
