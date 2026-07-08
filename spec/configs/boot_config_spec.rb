# frozen_string_literal: true

require "rails_helper"

RSpec.describe BootConfig do
  after do
    load_settings!
  end

  it "loads typed boot settings from environment overrides" do
    with_env(boot_env) do
      load_settings!

      expect_boot_settings!
    end
  end

  it "loads typed database settings from environment overrides" do
    with_env(database_env) do
      load_settings!

      expect_database_overrides!
    end
  end

  it "loads database defaults from the settings initializer" do
    with_env(default_database_env) do
      load_settings!

      expect_database_defaults!
    end
  end

  it "keeps production database defaults when Rails boots in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    with_env(
      "DB_USER" => nil,
      "DB_NAME" => nil,
      "DB_QUEUE_NAME" => nil,
      "ROUTEPRINT_DATABASE_PASSWORD" => nil
    ) do
      load_settings!

      expect_production_database_defaults!
    end
  end

  def load_settings!
    load Rails.root.join("config/initializers/01_settings.rb")
  end

  def boot_env
    {
      "CI" => "true",
      "PORT" => "3100",
      "RAILS_MAX_THREADS" => "7",
      "JOB_CONCURRENCY" => "3",
      "SOLID_QUEUE_IN_PUMA" => "1",
      "PIDFILE" => "tmp/pids/custom.pid",
      "RAILS_LOG_LEVEL" => "debug",
      "REDIS_URL" => "redis://redis:6379/4"
    }
  end

  def database_env
    {
      "DB_POOL" => "9",
      "DB_MAX_CONNECTIONS" => "11",
      "DB_HOST" => "postgres",
      "DB_PORT" => "5544",
      "DB_USER" => "route",
      "DB_PASSWORD" => "secret",
      "DB_NAME" => "routeprint_current",
      "DB_QUEUE_NAME" => "routeprint_current_queue",
      "DB_CACHE_NAME" => "routeprint_current_cache",
      "DB_CABLE_NAME" => "routeprint_current_cable",
      "ROUTEPRINT_DATABASE_PASSWORD" => "production-secret"
    }
  end

  def default_database_env
    {
      "DB_POOL" => nil,
      "DB_MAX_CONNECTIONS" => nil,
      "DB_HOST" => nil,
      "DB_PORT" => nil,
      "DB_USER" => nil,
      "DB_PASSWORD" => nil,
      "DB_NAME" => nil,
      "DB_QUEUE_NAME" => nil,
      "DB_CACHE_NAME" => nil,
      "DB_CABLE_NAME" => nil,
      "ROUTEPRINT_DATABASE_PASSWORD" => nil
    }
  end

  def with_env(values)
    previous_values = values.to_h { |key, _value| [ key, ENV[key] ] }

    values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    previous_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  def expect_boot_settings!
    aggregate_failures do
      expect(described_class.config.system.ci).to be(true)
      expect(described_class.config.server.port).to eq(3100)
      expect(described_class.config.server.rails_max_threads).to eq(7)
      expect(described_class.config.server.solid_queue_in_puma).to be(true)
      expect(described_class.config.jobs.concurrency).to eq(3)
      expect(described_class.config.logging.level).to eq(:debug)
      expect(described_class.config.redis.url).to eq("redis://redis:6379/4")
    end
  end

  def expect_database_overrides!
    aggregate_failures do
      expect(described_class.config.database.pool).to eq(9)
      expect(described_class.config.database.max_connections).to eq(11)
      expect(described_class.config.database.host).to eq("postgres")
      expect(described_class.config.database.port).to eq(5544)
      expect(described_class.config.database.username).to eq("route")
      expect(described_class.config.database.password).to eq("secret")
      expect(described_class.config.database.production_password).to eq("production-secret")
      expect(described_class.config.database.name).to eq("routeprint_current")
      expect(described_class.config.database.queue_name).to eq("routeprint_current_queue")
      expect(described_class.config.database.cache_name).to eq("routeprint_current_cache")
      expect(described_class.config.database.cable_name).to eq("routeprint_current_cable")
    end
  end

  def expect_database_defaults!
    aggregate_failures do
      expect(described_class.config.database.pool).to eq(5)
      expect(described_class.config.database.max_connections).to eq(5)
      expect(described_class.config.database.host).to eq("localhost")
      expect(described_class.config.database.username).to eq("postgres")
      expect(described_class.config.database.password).to eq("postgres")
      expect(described_class.config.database.production_password).to be_nil
      expect(described_class.config.database.name).to eq("routeprint_test")
      expect(described_class.config.database.queue_name).to eq("routeprint_test_queue")
      expect(described_class.config.database.cache_name).to eq("routeprint_production_cache")
      expect(described_class.config.database.cable_name).to eq("routeprint_production_cable")
    end
  end

  def expect_production_database_defaults!
    aggregate_failures do
      expect(described_class.config.database.username).to eq("routeprint")
      expect(described_class.config.database.name).to eq("routeprint_production")
      expect(described_class.config.database.queue_name).to eq("routeprint_production_queue")
    end
  end
end
