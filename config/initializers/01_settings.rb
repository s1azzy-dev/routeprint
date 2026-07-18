# frozen_string_literal: true

require_relative "../configs/boot_config"
require_relative "../configs/application_config"

environment_name = Rails.env.to_s
default_database_user = Rails.env.production? ? "routeprint" : "postgres"

BootConfig.configure do |config|
  config.system.ci = ENV.fetch("CI", false)

  config.server.rails_max_threads = ENV.fetch("RAILS_MAX_THREADS", 5)
  config.server.port = ENV.fetch("PORT", 3000)
  config.server.pidfile = ENV["PIDFILE"]
  config.server.solid_queue_in_puma = ENV.fetch("SOLID_QUEUE_IN_PUMA", false)

  config.jobs.concurrency = ENV.fetch("JOB_CONCURRENCY", 1)
  config.logging.level = ENV.fetch("RAILS_LOG_LEVEL", :info)
  config.redis.url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

  config.database.pool = ENV.fetch("DB_POOL", ENV.fetch("RAILS_MAX_THREADS", 5))
  config.database.max_connections = ENV.fetch("DB_MAX_CONNECTIONS", 5)
  config.database.host = ENV.fetch("DB_HOST", "localhost")
  config.database.port = ENV.fetch("DB_PORT", 5432)
  config.database.username = ENV.fetch("DB_USER", default_database_user)
  config.database.password = ENV.fetch("DB_PASSWORD", "postgres")
  config.database.production_password = ENV["ROUTEPRINT_DATABASE_PASSWORD"]
  config.database.name = ENV.fetch("DB_NAME", "routeprint_#{environment_name}")
  config.database.cache_name = ENV.fetch("DB_CACHE_NAME", "routeprint_production_cache")
  config.database.queue_name = ENV.fetch("DB_QUEUE_NAME", "routeprint_#{environment_name}_queue")
  config.database.cable_name = ENV.fetch("DB_CABLE_NAME", "routeprint_production_cable")
end

ApplicationConfig.configure do |config|
  config.urls.host = ENV.fetch("APP_HOST", "localhost")
  config.urls.port = ENV["APP_PORT"]
  config.urls.protocol = ENV.fetch("APP_PROTOCOL", "http")
  config.storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", :local)
  config.imports.ourairports.source_key = "ourairports_airports"
  config.imports.ourairports.source_url = ENV.fetch(
    "OURAIRPORTS_AIRPORTS_SOURCE_URL",
    "https://ourairports.com/data/airports.csv"
  )
  config.imports.countries.source_key = "country_catalog"
  config.imports.countries.ourairports_source_url = ENV.fetch(
    "OURAIRPORTS_COUNTRIES_SOURCE_URL",
    "https://ourairports.com/data/countries.csv"
  )
  config.imports.countries.cldr_release = ENV.fetch("CLDR_RELEASE", "48.2.1")
  config.imports.countries.cldr_source_url_template = ENV.fetch(
    "CLDR_TERRITORIES_SOURCE_URL_TEMPLATE",
    "https://raw.githubusercontent.com/unicode-org/cldr-json/%{release}/cldr-json/cldr-localenames-full/main/%{locale}/territories.json"
  )
end
