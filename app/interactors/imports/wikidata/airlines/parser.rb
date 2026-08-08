# frozen_string_literal: true

require "json"

module Imports
  module Wikidata
    module Airlines
      # Parses one SPARQL-results JSON page and groups evidence bindings by QID.
      class Parser
        QID_URI = %r{\Ahttp://www\.wikidata\.org/entity/(Q\d+)\z}

        # Parses one bounded Wikidata query response.
        #
        # @param io [#read] SPARQL-results JSON input
        # @return [Hash] grouped records and page cursor metadata
        def self.call(io)
          document = JSON.parse(io.read)
          bindings = document.fetch("results").fetch("bindings")
          raise FormatError, "results.bindings must be an array" unless bindings.is_a?(Array)

          grouped = bindings.group_by { |binding| qid_for(binding) }
          qids = grouped.keys.sort
          records = qids.map { |qid| record_for(qid, grouped.fetch(qid)) }

          {
            records:,
            binding_count: bindings.size,
            qid_count: qids.size,
            last_qid: qids.last
          }
        rescue KeyError, TypeError => error
          raise FormatError, error.message
        end

        def self.qid_for(binding)
          uri = binding.dig("airline", "value").to_s
          match = QID_URI.match(uri)
          raise FormatError, "airline binding must contain a Wikidata QID URI" unless match

          match[1]
        end
        private_class_method :qid_for

        def self.record_for(qid, bindings)
          names = bindings.filter_map { |binding| binding.dig("name", "value").to_s.squish.presence }.uniq.sort

          {
            raw_payload: {
              "qid" => qid,
              "name" => names.one? ? names.first : nil,
              "name_candidates" => names,
              "bindings" => bindings
            }
          }
        end
        private_class_method :record_for

        class FormatError < StandardError; end
      end
    end
  end
end
