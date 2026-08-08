# frozen_string_literal: true

require "net/http"
require "stringio"
require "uri"

module Imports
  module Wikidata
    module Airlines
      # Downloads and privately captures one bounded Wikidata airline page.
      #
      # @example
      #   Imports::Wikidata::Airlines::DownloadPage.call(input: { run:, item:, endpoint_url:, page_number: 1, after_qid: nil, page_size: 250 })
      # @param input [Hash] run, item, endpoint, page cursor, and page size
      class DownloadPage < ApplicationInteractor
        option :input
        option :capture_artifact, default: -> { Imports::CaptureArtifact }

        ALLOWED_HOST = "query.wikidata.org"
        MAX_BYTES = 8 * 1024 * 1024
        MAX_PAGE_SIZE = 500
        QUERY_VERSION = "1"
        QID = /\AQ\d+\z/

        class ValidationContract < ApplicationContract
          params do
            required(:run).filled(type?: Imports::Run)
            required(:item).filled(type?: Imports::RunItem)
            required(:endpoint_url).filled(:string)
            required(:page_number).filled(:integer, gteq?: 1)
            optional(:after_qid).maybe(:string)
            required(:page_size).filled(:integer, gteq?: 1, lteq?: MAX_PAGE_SIZE)
            required(:query_sha256).filled(:string)
          end
        end

        def call
          uri = yield parse_endpoint
          yield validate_endpoint(uri)
          after_qid = yield validate_cursor
          query_template = yield validated_query_template
          query = render_query(query_template:, after_qid:, page_size: input.fetch(:page_size))
          response = yield download(uri:, query:)
          body = yield validate_response(response)

          capture(body:, endpoint_url: uri.to_s, after_qid:)
        end

        private

        def parse_endpoint
          Success(URI.parse(input.fetch(:endpoint_url)))
        rescue URI::InvalidURIError
          fail_with(code: :invalid_source_url, errors: { endpoint_url: [ "is not a valid URL" ] })
        end

        def validate_endpoint(uri)
          return Success(uri) if uri.is_a?(URI::HTTPS) && uri.host.to_s.downcase == ALLOWED_HOST && uri.path == "/sparql"

          fail_with(code: :invalid_source_url, errors: { endpoint_url: [ "must be the HTTPS Wikidata Query Service endpoint" ] })
        end

        def validate_cursor
          after_qid = input[:after_qid].presence
          return Success(nil) unless after_qid
          return Success(after_qid) if after_qid.match?(QID)

          fail_with(code: :invalid_page_cursor, errors: { after_qid: [ "must be a Wikidata QID" ] })
        end

        def validated_query_template
          query_template = query_path.read
          actual_sha256 = Digest::SHA256.hexdigest(query_template)
          return Success(query_template) if input.fetch(:query_sha256) == actual_sha256

          fail_with(code: :query_version_mismatch, errors: { query_sha256: [ "does not match the configured query" ] })
        end

        def render_query(query_template:, after_qid:, page_size:)
          format(
            query_template,
            after_qid_uri: after_qid ? "http://www.wikidata.org/entity/#{after_qid}" : "",
            page_size:
          )
        end

        def query_path
          Rails.root.join("config/imports/wikidata_airlines_v1.sparql")
        end

        def download(uri:, query:)
          request = Net::HTTP::Post.new(uri.request_uri)
          request["Accept"] = "application/sparql-results+json"
          request["User-Agent"] = "Routeprint airline reference import"
          request.set_form_data(query:)

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 120) do |http|
            http.request(request)
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

        def capture(body:, endpoint_url:, after_qid:)
          page_number = input.fetch(:page_number)
          capture_artifact.call(
            input: {
              run: input.fetch(:run),
              run_item: input.fetch(:item),
              kind: "source_dump",
              io: StringIO.new(body),
              filename: format("wikidata-airlines-page-%04d.json", page_number),
              content_type: "application/sparql-results+json",
              source_url: endpoint_url,
              metadata: {
                "provider" => "wikidata",
                "dataset" => "airlines",
                "page_number" => page_number,
                "after_qid" => after_qid,
                "query_version" => QUERY_VERSION,
                "query_sha256" => input.fetch(:query_sha256)
              }
            }
          )
        end
      end
    end
  end
end
