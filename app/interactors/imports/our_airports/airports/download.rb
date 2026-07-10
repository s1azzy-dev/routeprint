require "net/http"
require "stringio"
require "uri"

module Imports
  module OurAirports
    module Airports
      class Download < ApplicationInteractor
        option :input

        ALLOWED_HOSTS = %w[ourairports.com www.ourairports.com].freeze
        MAX_BYTES = 64 * 1024 * 1024

        def call
          run = input.fetch(:run)
          item = input[:item]
          url = input[:source_url].presence || run.params.to_h["source_url"].presence || run.source.config.to_h["source_url"].presence
          uri = URI.parse(url.to_s)
          return fail_with(code: :invalid_source_url, errors: { source_url: [ "must be an HTTPS OurAirports URL" ] }) unless allowed_uri?(uri)

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
            http.get(uri.request_uri)
          end
          return fail_with(code: :source_download_failed, errors: { status: [ response.code ] }) unless response.is_a?(Net::HTTPSuccess)
          return fail_with(code: :source_artifact_too_large, errors: { byte_size: [ "exceeds limit" ] }) if response.body.bytesize > MAX_BYTES

          CaptureArtifact.call(
            input: {
              run:,
              run_item: item,
              kind: "source_dump",
              io: StringIO.new(response.body),
              filename: "ourairports-airports.csv",
              content_type: "text/csv",
              source_url: url,
              metadata: { "provider" => "ourairports", "dataset" => "airports" }
            }
          )
        rescue URI::InvalidURIError
          fail_with(code: :invalid_source_url, errors: { source_url: [ "is not a valid URL" ] })
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => error
          fail_with(code: :source_download_failed, errors: { message: [ error.class.name ] })
        rescue KeyError => error
          fail_with(code: :validation_error, errors: { input: [ error.message ] })
        end

        private

        def allowed_uri?(uri)
          uri.is_a?(URI::HTTPS) && ALLOWED_HOSTS.include?(uri.host.to_s.downcase)
        end
      end
    end
  end
end
