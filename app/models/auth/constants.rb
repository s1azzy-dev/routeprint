module Auth
  module Constants
    MINIMUM_PASSWORD_LENGTH = 12
    PASSWORD_RESET_TTL = 30.minutes
    LAST_SEEN_TOUCH_INTERVAL = 10.minutes

    PROVIDERS = [
      PASSWORD = "password",
      GOOGLE = "google",
      APPLE = "apple",
      EMAIL_CODE = "email_code"
    ].freeze
  end
end
