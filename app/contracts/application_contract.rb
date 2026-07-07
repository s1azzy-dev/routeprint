# frozen_string_literal: true

class ApplicationContract < Yabi::BaseContract
  config.messages.default_locale = :en
  config.messages.load_paths << Rails.root.join("config/locales/en.yml")
  config.messages.load_paths << Rails.root.join("config/locales/ru.yml")
end
