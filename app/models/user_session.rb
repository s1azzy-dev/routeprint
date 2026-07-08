require "digest"

class UserSession < ApplicationRecord
  belongs_to :user
  belongs_to :user_identity

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  validates :authentication_method, presence: true, inclusion: { in: Auth::Constants::PROVIDERS }
  validates :token_digest, presence: true, uniqueness: true
  validates :last_seen_at, presence: true
  validates :expires_at, presence: true

  def active?
    !revoked? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_seen_if_stale!
    return if last_seen_at > Auth::Constants::LAST_SEEN_TOUCH_INTERVAL.ago

    update!(last_seen_at: Time.current)
  end

  def self.digest_token(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.find_by_token(token)
    find_by(token_digest: digest_token(token))
  end
end
