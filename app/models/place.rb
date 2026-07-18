class Place < ApplicationRecord
  KINDS = %w[airport].freeze

  belongs_to :country, optional: true
  has_many :place_names, dependent: :destroy
  has_one :airport, dependent: :destroy

  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :kind, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :country_code, with: ->(value) { value.to_s.strip.upcase.presence }
  normalizes :region_code, with: ->(value) { value.to_s.strip.upcase.presence }
  normalizes :continent_code, with: ->(value) { value.to_s.strip.upcase.presence }
  normalizes :time_zone, with: ->(value) { value.to_s.strip.presence }
  normalizes :time_zone_source, with: ->(value) { value.to_s.strip.presence }

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :name, presence: true
  validates :country_code, presence: true, format: { with: /\A[A-Z]{2}\z/ }
  validates :location, presence: true
  validate :time_zone_is_known
  validate :timezone_metadata_requires_timezone

  def name_for(locale)
    place_names.find_by(locale: locale.to_s.strip.downcase)&.name || name
  end

  private

  def time_zone_is_known
    return if time_zone.blank?

    TZInfo::Timezone.get(time_zone)
  rescue TZInfo::InvalidTimezoneIdentifier
    errors.add(:time_zone, "is not a valid IANA timezone")
  end

  def timezone_metadata_requires_timezone
    return if time_zone.present? || (time_zone_source.blank? && time_zone_verified_at.blank?)

    errors.add(:time_zone, "is required when timezone metadata is present")
  end
end
