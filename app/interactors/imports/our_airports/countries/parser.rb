# frozen_string_literal: true

require "csv"

module Imports
  module OurAirports
    module Countries
      # Parses the OurAirports country-membership CSV.
      class Parser
        def self.call(io)
          new(io).call
        end

        def initialize(io)
          @io = io
        end

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
