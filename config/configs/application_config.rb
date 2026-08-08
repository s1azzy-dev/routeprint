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

  setting :imports do
    setting :ourairports do
      setting :source_key, constructor: Types::String.constrained(filled: true)
      setting :source_url, constructor: Types::String.constrained(filled: true)
    end

    setting :wikidata_airlines do
      setting :source_key, constructor: Types::String.constrained(filled: true)
      setting :endpoint_url, constructor: Types::String.constrained(filled: true)
      setting :page_size, constructor: Types::Params::Integer.constrained(gteq: 1, lteq: 500)
      setting :max_pages, constructor: Types::Params::Integer.constrained(gteq: 1, lteq: 100)
    end

    setting :countries do
      setting :source_key, constructor: Types::String.constrained(filled: true)
      setting :ourairports_source_url, constructor: Types::String.constrained(filled: true)
      setting :cldr_release, constructor: Types::String.constrained(filled: true)
      setting :cldr_source_url_template, constructor: Types::String.constrained(filled: true)
    end
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
