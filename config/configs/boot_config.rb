# frozen_string_literal: true

require_relative "configurable"

class BootConfig
  extend Routeprint::Configurable

  PositiveInteger = Types::Params::Integer.constrained(gt: 0)
  OptionalString = Types::String.optional
  StringBool = Types::Params::Bool
  LogLevel = Types::Symbol.constructor { _1.to_s.downcase.to_sym }
    .enum(:debug, :info, :warn, :error, :fatal, :unknown)

  setting :system do
    setting :ci, constructor: StringBool
  end

  setting :server do
    setting :rails_max_threads, constructor: PositiveInteger
    setting :port, constructor: PositiveInteger
    setting :pidfile, constructor: OptionalString
    setting :solid_queue_in_puma, constructor: StringBool
  end

  setting :jobs do
    setting :concurrency, constructor: PositiveInteger
  end

  setting :logging do
    setting :level, constructor: LogLevel
  end

  setting :redis do
    setting :url, constructor: Types::String.constrained(filled: true)
  end

  setting :database do
    setting :pool, constructor: PositiveInteger
    setting :max_connections, constructor: PositiveInteger
    setting :host, constructor: Types::String.constrained(filled: true)
    setting :port, constructor: PositiveInteger
    setting :username, constructor: Types::String.constrained(filled: true)
    setting :password, constructor: Types::String
    setting :production_password, constructor: OptionalString
    setting :name, constructor: Types::String.constrained(filled: true)
    setting :cache_name, constructor: Types::String.constrained(filled: true)
    setting :queue_name, constructor: Types::String.constrained(filled: true)
    setting :cable_name, constructor: Types::String.constrained(filled: true)
  end
end
