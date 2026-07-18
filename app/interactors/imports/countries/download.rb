# frozen_string_literal: true

require "net/http"
require "stringio"
require "uri"

module Imports
  module Countries
    # Downloads one server-defined country-catalog artifact through an allowlisted host.
    #
    # @example Imports::Countries::Download.call(input: { run:, item:, artifact_key: "ourairports_countries", provider_key: "ourairports", dataset_key: "countries", source_url: url, filename: "countries.csv", content_type: "text/csv" })
    # @param input [Hash] server-defined country-catalog artifact descriptor
    class Download < ApplicationInteractor
      option :input
      option :capture_artifact, default: -> { Imports::CaptureArtifact }

      ALLOWED_HOSTS = {
        "ourairports" => %w[ourairports.com www.ourairports.com],
        "unicode_cldr" => %w[raw.githubusercontent.com]
      }.freeze
      MAX_BYTES = 64 * 1024 * 1024

      class ValidationContract < ApplicationContract
        params do
          required(:run).filled(type?: Imports::Run)
          required(:item).filled(type?: Imports::RunItem)
          required(:artifact_key).filled(:string)
          required(:provider_key).filled(:string)
          required(:dataset_key).filled(:string)
          required(:source_url).filled(:string)
          required(:filename).filled(:string)
          required(:content_type).filled(:string)
          optional(:locale).maybe(:string)
        end
      end

      def call
        uri = yield parse_uri(input.fetch(:source_url))
        yield validate_uri(uri, input.fetch(:provider_key))
        response = yield download(uri)
        body = yield validate_response(response)

        capture_artifact.call(
          input: {
            run: input.fetch(:run),
            run_item: input.fetch(:item),
            kind: "source_dump",
            io: StringIO.new(body),
            filename: input.fetch(:filename),
            content_type: input.fetch(:content_type),
            source_url: input.fetch(:source_url),
            metadata: metadata
          }
        )
      end

      private

      def metadata
        {
          "artifact_key" => input.fetch(:artifact_key),
          "provider" => input.fetch(:provider_key),
          "dataset" => input.fetch(:dataset_key),
          "locale" => input[:locale]
        }.compact
      end

      def parse_uri(source_url)
        Success(URI.parse(source_url))
      rescue URI::InvalidURIError
        fail_with(code: :invalid_source_url, errors: { source_url: [ "is not a valid URL" ] })
      end

      def validate_uri(uri, provider_key)
        allowed_hosts = ALLOWED_HOSTS.fetch(provider_key, [])
        return Success(uri) if uri.is_a?(URI::HTTPS) && allowed_hosts.include?(uri.host.to_s.downcase)

        fail_with(code: :invalid_source_url, errors: { source_url: [ "is not an allowed HTTPS source URL" ] })
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
    end
  end
end
