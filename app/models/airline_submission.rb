class AirlineSubmission < ApplicationRecord
  belongs_to :airline
  belongs_to :submitted_by_user, class_name: "User", optional: true
  belongs_to :submitted_country, class_name: "Country", optional: true

  normalizes :submitted_name, with: ->(value) { value.to_s.squish.presence }
  normalizes :submitted_code, with: ->(value) { value.to_s.strip.upcase.presence }

  validates :submitted_name, presence: true
  validates :airline_id, uniqueness: true
  validate :airline_is_not_a_system_placeholder

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  private

  def prevent_mutation
    errors.add(:base, :readonly)
    throw(:abort)
  end

  def airline_is_not_a_system_placeholder
    return unless airline&.record_kind == "system_placeholder"

    errors.add(:airline, :invalid)
  end
end
