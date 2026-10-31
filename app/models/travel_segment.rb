class TravelSegment < ApplicationRecord
  belongs_to :user
  belongs_to :departure_place, class_name: "Place"
  belongs_to :arrival_place, class_name: "Place"
  has_one :flight_detail, dependent: :destroy, autosave: true, inverse_of: :travel_segment
end
