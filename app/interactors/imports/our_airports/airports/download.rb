require "net/http"
require "stringio"
require "uri"

module Imports
  module OurAirports
    module Airports
      # Downloads and captures the complete OurAirports airport CSV artifact.
      #
      # @example
      #   Imports::OurAirports::Airports::Download.call(input: { run:, item:, source_url: url })
      # @param input [Hash] run, optional item, and optional source URL
      class Download < ApplicationInteractor
        option :input
        option :capture_artifact, default: -> { Imports::CaptureArtifact }

        ALLOWED_HOSTS = %w[ourairports.com www.ourairports.com].freeze
        MAX_BYTES = 64 * 1024 * 1024

        class ValidationContract < ApplicationContract
          params do
            required(:run).filled(type?: Imports::Run)
            optional(:item).maybe(type?: Imports::RunItem)
            optional(:source_url).maybe(:string)
          end
        end

        def call
          run = input.fetch(:run)
          item = input[:item]
          source_url = yield find_source_url(run)
          uri = yield parse_source_uri(source_url)
          yield validate_source_uri(uri)
          response = yield download(uri)
          body = yield validate_response(response)

          persist_artifact(run:, item:, source_url:, body:)
        end

        private

        def find_source_url(run)
          source_url = input[:source_url].presence || run.params.to_h["source_url"].presence || run.source.config.to_h["source_url"].presence
          return Success(source_url) if source_url.present?

          fail_with(code: :invalid_source_url, errors: { source_url: [ "is required" ] })
        end

        def parse_source_uri(source_url)
          Success(URI.parse(source_url))
        rescue URI::InvalidURIError
          fail_with(code: :invalid_source_url, errors: { source_url: [ "is not a valid URL" ] })
        end

        def validate_source_uri(uri)
          return Success(uri) if allowed_uri?(uri)

          fail_with(code: :invalid_source_url, errors: { source_url: [ "must be an HTTPS OurAirports URL" ] })
        end

        def download(uri)
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
            http.get(uri.request_uri)
          end

          Success(response)
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => error
          fail_with(code: :source_download_failed, errors: { message: [ error.class.name ] })
        end

        def validate_response(response)
          return fail_with(code: :source_download_failed, errors: { status: [ response.code ] }) unless response.is_a?(Net::HTTPSuccess)
          return fail_with(code: :source_artifact_too_large, errors: { byte_size: [ "exceeds limit" ] }) if response.body.bytesize > MAX_BYTES

          Success(response.body)
        end

        def persist_artifact(run:, item:, source_url:, body:)
          capture_artifact.call(
            input: {
              run:,
              run_item: item,
              kind: "source_dump",
              io: StringIO.new(body),
              filename: "ourairports-airports.csv",
              content_type: "text/csv",
              source_url:,
              metadata: { "provider" => "ourairports", "dataset" => "airports" }
            }
          )
        end

        def allowed_uri?(uri)
          uri.is_a?(URI::HTTPS) && ALLOWED_HOSTS.include?(uri.host.to_s.downcase)
        end
      end
    end
  end
end
