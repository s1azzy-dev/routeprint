# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationConfig do
  after do
    load_settings!
  end

  it "loads typed application settings from environment overrides" do
    with_env(environment_overrides) do
      load_settings!

      expect_application_settings!
    end
  end

  it "omits blank optional url ports" do
    with_env(
      "APP_HOST" => "routeprint.test",
      "APP_PORT" => nil,
      "APP_PROTOCOL" => "http",
      "ACTIVE_STORAGE_SERVICE" => "local"
    ) do
      load_settings!

      expect(described_class.default_url_options).to eq(
        host: "routeprint.test",
        protocol: "http"
      )
    end
  end

  def expect_application_settings!
    aggregate_failures do
      expect(described_class.config.urls.host).to eq("routeprint.test")
      expect(described_class.config.urls.port).to eq(3100)
      expect(described_class.config.urls.protocol).to eq("https")
      expect(described_class.config.storage.service).to eq(:test)
      expect(described_class.config.imports.ourairports.source_key).to eq("ourairports_airports")
      expect(described_class.config.imports.ourairports.source_url).to eq("https://data.example.test/airports.csv")
      expect(described_class.config.imports.countries).to have_attributes(
        source_key: "country_catalog",
        ourairports_source_url: "https://data.example.test/countries.csv",
        cldr_release: "48.2.1-test",
        cldr_source_url_template: "https://data.example.test/%{release}/%{locale}.json"
      )
      expect(described_class.default_url_options).to eq(
        host: "routeprint.test",
        port: 3100,
        protocol: "https"
      )
    end
  end

  def environment_overrides
    {
      "APP_HOST" => "routeprint.test", "APP_PORT" => "3100", "APP_PROTOCOL" => "https", "ACTIVE_STORAGE_SERVICE" => "test",
      "OURAIRPORTS_AIRPORTS_SOURCE_URL" => "https://data.example.test/airports.csv",
      "OURAIRPORTS_COUNTRIES_SOURCE_URL" => "https://data.example.test/countries.csv", "CLDR_RELEASE" => "48.2.1-test",
      "CLDR_TERRITORIES_SOURCE_URL_TEMPLATE" => "https://data.example.test/%{release}/%{locale}.json"
    }
  end

  def load_settings!
    load Rails.root.join("config/initializers/01_settings.rb")
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
end
