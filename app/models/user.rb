class User < ApplicationRecord
  ROLES = %w[member admin].freeze
  STATUSES = %w[active suspended].freeze

  has_many :user_identities, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :airline_submissions,
    foreign_key: :submitted_by_user_id,
    inverse_of: :submitted_by_user,
    dependent: :nullify
  has_many :reviewed_airlines,
    class_name: "Airline",
    foreign_key: :reviewed_by_user_id,
    inverse_of: :reviewed_by,
    dependent: :nullify

  normalizes :primary_email, with: ->(value) { EmailNormalizer.normalize(value) }
  normalizes :display_name, with: ->(value) { value.to_s.squish.presence }

  validates :primary_email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }

  def active?
    status == "active"
  end

  def admin?
    role == "admin"
  end

  def suspended?
    status == "suspended"
  end
end
