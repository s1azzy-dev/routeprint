class CountryName < ApplicationRecord
  belongs_to :country
  has_one :source_link,
    class_name: "Imports::CountryNameSourceLink",
    dependent: :restrict_with_exception

  normalizes :locale, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :name, with: ->(value) { value.to_s.squish.presence }

  validates :locale, presence: true,
    inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s).map(&:downcase) } }
  validates :name, presence: true
  validates :locale, uniqueness: { scope: :country_id }
end
