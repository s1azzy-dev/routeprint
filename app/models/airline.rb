class Airline < ApplicationRecord
  REVIEW_STATUSES = %w[pending approved rejected merged].freeze
  OPERATIONAL_STATUSES = %w[active inactive unknown].freeze
  RECORD_KINDS = %w[catalog system_placeholder].freeze
  SYSTEM_KEYS = %w[unknown_airline].freeze
  UNKNOWN_SYSTEM_KEY = "unknown_airline"

  belongs_to :country, optional: true
  belongs_to :merged_into, class_name: "Airline", optional: true
  belongs_to :reviewed_by,
    class_name: "User",
    foreign_key: :reviewed_by_user_id,
    inverse_of: :reviewed_airlines,
    optional: true

  has_many :merged_airlines,
    class_name: "Airline",
    foreign_key: :merged_into_id,
    inverse_of: :merged_into,
    dependent: :restrict_with_exception
  has_many :designators,
    class_name: "AirlineDesignator",
    dependent: :restrict_with_exception
  has_one :submission,
    class_name: "AirlineSubmission",
    dependent: :restrict_with_exception
  has_many :source_links,
    class_name: "Imports::AirlineSourceLink",
    dependent: :restrict_with_exception

  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :review_status, :operational_status, :record_kind, :system_key,
    with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :pending_fingerprint, with: ->(value) { value.to_s.strip.downcase.presence }

  before_validation :assign_normalized_name
  before_update :prevent_system_airline_mutation, if: :protected_system_airline?
  before_destroy :prevent_system_airline_mutation, if: :protected_system_airline?

  validates :name, :normalized_name, presence: true
  validates :review_status, presence: true, inclusion: { in: REVIEW_STATUSES }
  validates :operational_status, presence: true, inclusion: { in: OPERATIONAL_STATUSES }
  validates :record_kind, presence: true, inclusion: { in: RECORD_KINDS }
  validates :system_key, inclusion: { in: SYSTEM_KEYS }, allow_nil: true
  validate :merge_target_matches_review_state
  validate :merge_target_is_approved_catalog_record
  validate :system_key_matches_record_kind
  validate :system_airline_has_fixed_lifecycle

  private

  def assign_normalized_name
    self.normalized_name = name.to_s.squish.downcase.presence
  end

  def merge_target_matches_review_state
    if review_status == "merged" && merged_into.nil?
      errors.add(:merged_into, :blank)
    elsif review_status != "merged" && merged_into.present?
      errors.add(:merged_into, :invalid)
    elsif merged_into.equal?(self)
      errors.add(:merged_into, :invalid)
    end
  end

  def merge_target_is_approved_catalog_record
    return if merged_into.nil? || merged_into.equal?(self)
    return if merged_into.review_status == "approved" && merged_into.record_kind == "catalog"

    errors.add(:merged_into, :invalid)
  end

  def system_key_matches_record_kind
    if record_kind == "system_placeholder" && system_key.blank?
      errors.add(:system_key, :blank)
    elsif record_kind != "system_placeholder" && system_key.present?
      errors.add(:system_key, :invalid)
    end
  end

  def system_airline_has_fixed_lifecycle
    return unless system_key == UNKNOWN_SYSTEM_KEY
    return if review_status == "approved" && operational_status == "unknown" && record_kind == "system_placeholder"

    errors.add(:base, :invalid)
  end

  def protected_system_airline?
    system_key == UNKNOWN_SYSTEM_KEY || system_key_in_database == UNKNOWN_SYSTEM_KEY
  end

  def prevent_system_airline_mutation
    errors.add(:base, "protected system airline cannot be changed")
    throw(:abort)
  end
end
