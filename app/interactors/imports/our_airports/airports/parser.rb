require "csv"

module Imports
  module OurAirports
    module Airports
      # Parses an OurAirports CSV stream into row-numbered raw payloads.
      class Parser
        HEADERS = %w[
          id ident type name latitude_deg longitude_deg elevation_ft continent
          iso_country iso_region municipality scheduled_service icao_code
          iata_code gps_code local_code home_link wikipedia_link keywords
        ].freeze

        # Parses rows from an IO-like source.
        #
        # @param io [Object] rewindable CSV input
        # @return [Array<Hash>] raw payloads with source row numbers
        def self.call(io)
          new(io).call
        end

        # Builds a parser for an IO-like source.
        #
        # @param io [Object] CSV input
        def initialize(io)
          @io = io
        end

        # Reads and converts the complete CSV stream.
        #
        # @return [Array<Hash>] row-numbered raw payloads
        def call
          @io.rewind if @io.respond_to?(:rewind)
          CSV.new(@io, headers: true, liberal_parsing: false).each_with_index.map do |row, index|
            { row_number: index + 2, raw_payload: row.to_h.transform_keys(&:to_s) }
          end
        end
      end
    end
  end
end
