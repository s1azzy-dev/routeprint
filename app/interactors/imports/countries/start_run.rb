# frozen_string_literal: true

module Imports
  module Countries
    # Starts one composite country-catalog run with all required provider artifacts.
    #
    # @example Imports::Countries::StartRun.call(input: { initiated_by_user_id: user.id })
    # @param input [Hash] optional catalog-refresh initiator identifier
    class StartRun < ApplicationInteractor
      option :input
      option :start_run, default: -> { Imports::StartRun }

      OURAIRPORTS_PARSER_VERSION = "1"
      CLDR_PARSER_VERSION = "1"
      CLDR_LOCALES = %w[en ru].freeze

      class ValidationContract < ApplicationContract
        params do
          optional(:initiated_by_user_id).maybe(:string)
        end
      end

      def call
        yield validate_source
        start_run.call(input: run_input)
      end

      private

      def validate_source
        source = Imports::Source.find_by(key: settings.source_key)
        return fail_with(code: :country_source_unavailable, errors: { source_key: [ settings.source_key ] }) unless source&.enabled?
        return Success() unless source.runs.active.exists?

        fail_with(code: :country_source_unavailable, errors: { source_key: [ settings.source_key ] })
      end

      def run_input
        {
          source_key: settings.source_key,
          mode: "full",
          params: {
            "ourairports_source_url" => settings.ourairports_source_url,
            "cldr_release" => settings.cldr_release,
            "parser_versions" => {
              "ourairports" => OURAIRPORTS_PARSER_VERSION,
              "cldr" => CLDR_PARSER_VERSION
            }
          },
          items: [
            {
              item_kind: "catalog",
              item_key: "all",
              params: { "artifacts" => artifact_inputs }
            }
          ],
          initiated_by_user_id: input[:initiated_by_user_id]
        }
      end

      def artifact_inputs
        [
          {
            "key" => "ourairports_countries",
            "provider_key" => "ourairports",
            "dataset_key" => "countries",
            "source_url" => settings.ourairports_source_url,
            "filename" => "ourairports-countries.csv",
            "content_type" => "text/csv"
          },
          *CLDR_LOCALES.map do |locale|
            {
              "key" => "cldr_territories_#{locale}",
              "provider_key" => "unicode_cldr",
              "dataset_key" => "territories",
              "locale" => locale,
              "source_url" => cldr_source_url(locale),
              "filename" => "cldr-territories-#{locale}.json",
              "content_type" => "application/json"
            }
          end
        ]
      end

      def cldr_source_url(locale)
        format(settings.cldr_source_url_template, release: settings.cldr_release, locale:)
      end

      def settings
        ApplicationConfig.config.imports.countries
      end
    end
  end
end
