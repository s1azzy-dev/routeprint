class User < ApplicationRecord
  ROLES = %w[member admin].freeze
  STATUSES = %w[active suspended].freeze

  has_many :user_identities, dependent: :destroy
  has_many :user_sessions, dependent: :destroy

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
