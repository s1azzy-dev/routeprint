module Imports
  module OurAirports
    # Starts the configured full OurAirports airport import.
    #
    # @example
    #   Imports::OurAirports::StartRun.call(input: { initiated_by_user_id: user.id })
    # @param input [Hash] optional import initiator identifier
    class StartRun < ApplicationInteractor
      option :input
      option :start_run, default: -> { Imports::StartRun }

      PARSER_VERSION = "1"

      class ValidationContract < ApplicationContract
        params do
          optional(:initiated_by_user_id).maybe(:string)
        end
      end

      def call
        initiated_by_user_id = input[:initiated_by_user_id]
        source_url = settings.source_url

        start_run.call(
          input: {
            source_key: settings.source_key,
            mode: "full",
            params: { "source_url" => source_url, "parser_version" => PARSER_VERSION },
            items: [
              {
                item_kind: "file",
                item_key: "all",
                params: { "source_url" => source_url }
              }
            ],
            initiated_by_user_id:
          }
        )
      end

      private

      def settings
        ApplicationConfig.config.imports.ourairports
      end
    end
  end
end
