# frozen_string_literal: true

module Imports
  module Wikidata
    module Airlines
      # Starts the configured full Wikidata airline import.
      #
      # @example
      #   Imports::Wikidata::Airlines::StartRun.call(input: { initiated_by_user_id: user.id })
      # @param input [Hash] optional import initiator identifier
      class StartRun < ApplicationInteractor
        option :input
        option :start_run, default: -> { Imports::StartRun }

        QUERY_VERSION = "1"
        PARSER_VERSION = "1"

        class ValidationContract < ApplicationContract
          params do
            optional(:initiated_by_user_id).maybe(:string)
          end
        end

        def call
          params = {
            "endpoint_url" => settings.endpoint_url,
            "query_version" => QUERY_VERSION,
            "parser_version" => PARSER_VERSION,
            "page_size" => settings.page_size,
            "max_pages" => settings.max_pages,
            "query_sha256" => Digest::SHA256.file(query_path).hexdigest
          }

          start_run.call(
            input: {
              source_key: settings.source_key,
              mode: "full",
              params:,
              items: [ { item_kind: "catalog", item_key: "all", params: } ],
              initiated_by_user_id: input[:initiated_by_user_id]
            }
          )
        end

        private

        def settings
          ApplicationConfig.config.imports.wikidata_airlines
        end

        def query_path
          Rails.root.join("config/imports/wikidata_airlines_v1.sparql")
        end
      end
    end
  end
end
