class TravelSegment < ApplicationRecord
  RESOLUTIONS = %w[date_only not_provided resolved ambiguous nonexistent missing_zone].freeze

  belongs_to :user
  belongs_to :departure_place, class_name: "Place"
  belongs_to :arrival_place, class_name: "Place"
  has_one :flight_detail, dependent: :destroy, autosave: true, inverse_of: :travel_segment

  scope :with_display_references, -> {
    includes(departure_place: [ :airport, :place_names ], arrival_place: [ :airport, :place_names ],
      flight_detail: { marketing_airline: [ :designators, country: :country_names ],
        operating_airline: [ :designators, country: :country_names ] })
  }

  validates :transport_mode, inclusion: { in: [ "flight" ] }
  validates :departure_date, :creation_request_key, :creation_digest, :flight_detail, presence: true
  validates :departure_resolution, :arrival_resolution, inclusion: { in: RESOLUTIONS }
  validates_associated :flight_detail
  validate :airport_route
  validate :resolved_chronology

  private

  def airport_route
    errors.add(:arrival_place, :invalid) if departure_place && departure_place == arrival_place
    %i[departure_place arrival_place].each do |role|
      place = public_send(role)
      errors.add(role, :invalid) if place && !place.airport
    end
  end

  def resolved_chronology
    return unless departure_at && arrival_at && arrival_at <= departure_at

    errors.add(:arrival_date, :invalid)
  end
end
