# frozen_string_literal: true

require "json"

module Imports
  module Cldr
    module Territories
      # Parses one CLDR territory locale document into country-code records.
      class Parser
        def self.call(io)
          new(io).call
        end

        def initialize(io)
          @io = io
        end

        def call
          @io.rewind if @io.respond_to?(:rewind)
          document = JSON.parse(@io.read)
          locale, payload = document.fetch("main").first
          territories = payload.fetch("localeDisplayNames").fetch("territories")

          territories.filter_map.with_index do |(code, name), index|
            next unless code.match?(/\A[A-Z]{2}\z/)

            {
              row_number: index + 1,
              raw_payload: { "id" => "#{locale}:#{code}", "code" => code, "locale" => locale, "name" => name }
            }
          end
        end
      end
    end
  end
end
