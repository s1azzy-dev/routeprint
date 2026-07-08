require "digest"

class UserIdentity < ApplicationRecord
  belongs_to :user
  has_many :user_sessions, dependent: :destroy

  has_secure_password validations: false

  normalizes :email, with: ->(value) { EmailNormalizer.normalize(value) }
  normalizes :provider, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :provider, presence: true, inclusion: { in: Auth::Constants::PROVIDERS }
  validates :password_reset_token_digest, uniqueness: true, allow_nil: true
  validates :password,
    confirmation: true,
    length: { minimum: Auth::Constants::MINIMUM_PASSWORD_LENGTH },
    if: :password_provider_with_password?
  validates :password_confirmation, presence: true, if: :password_provider_with_password?
  validates :provider_uid, uniqueness: { scope: :provider }, allow_nil: true
  validate :password_identity_requires_password_digest
  validate :password_identity_unique_per_user
  validate :external_identity_requires_provider_uid

  scope :password, -> { where(provider: Auth::Constants::PASSWORD) }

  def password_reset_expired?
    password_reset_sent_at.blank? || password_reset_sent_at <= Auth::Constants::PASSWORD_RESET_TTL.ago
  end

  def self.digest_token(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.find_by_password_reset_token(token)
    find_by(password_reset_token_digest: digest_token(token))
  end

  def self.generate_token
    SecureRandom.urlsafe_base64(48)
  end

  private

  def external_identity_requires_provider_uid
    return if provider.blank? || provider == Auth::Constants::PASSWORD
    return if provider_uid.present?

    errors.add(:provider_uid, :blank)
  end

  def password_identity_requires_password_digest
    return unless provider == Auth::Constants::PASSWORD
    return if password_digest.present?

    errors.add(:password_digest, :blank)
  end

  def password_identity_unique_per_user
    return unless provider == Auth::Constants::PASSWORD && user_id.present?
    return unless self.class.password.where(user_id:).where.not(id:).exists?

    errors.add(:user_id, "already has a password identity")
  end

  def password_provider_with_password?
    provider == Auth::Constants::PASSWORD && password.present?
  end
end
