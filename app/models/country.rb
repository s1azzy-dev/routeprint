class Country < ApplicationRecord
  has_many :country_names, dependent: :destroy
  has_many :places, dependent: :restrict_with_exception
  has_many :country_source_links,
    class_name: "Imports::CountrySourceLink",
    dependent: :restrict_with_exception

  normalizes :code, with: ->(value) { value.to_s.strip.upcase.presence }
  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :continent_code, with: ->(value) { value.to_s.strip.upcase.presence }

  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[A-Z]{2}\z/ }
  validates :name, :continent_code, presence: true

  def name_for(locale)
    country_names.find_by(locale: locale.to_s.strip.downcase)&.name || name
  end
end
