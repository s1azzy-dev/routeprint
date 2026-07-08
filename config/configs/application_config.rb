# frozen_string_literal: true

require_relative "configurable"

class ApplicationConfig
  extend Routeprint::Configurable

  OptionalInteger = Types::Params::Integer.optional
  StorageService = Types::Symbol.constructor { _1.to_s.to_sym }

  setting :urls do
    setting :host, constructor: Types::String.constrained(filled: true)
    setting :port, constructor: OptionalInteger
    setting :protocol, constructor: Types::String.constrained(filled: true)
  end

  setting :storage do
    setting :service, constructor: StorageService
  end

  def self.default_url_options
    options = {
      host: config.urls.host,
      protocol: config.urls.protocol
    }
    options[:port] = config.urls.port if config.urls.port
    options
  end
end
