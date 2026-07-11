module Imports
  # Stores a complete import input as a private Active Storage artifact.
  #
  # @example
  #   Imports::CaptureArtifact.call(input: {
  #     run:, io:, filename: "airports.csv", content_type: "text/csv", kind: "source_dump"
  #   })
  # @param input [Hash] artifact metadata and an IO-like source
  class CaptureArtifact < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:run).filled(type?: Imports::Run)
        required(:io).filled
        required(:filename).filled(:string)
        required(:content_type).filled(:string)
        required(:kind).filled(:string)
        optional(:run_item).maybe(type?: Imports::RunItem)
        optional(:source_url).maybe(:string)
        optional(:metadata).maybe(:hash)
      end
    end

    def call
      io = input.fetch(:io)
      content = yield read_content(io)
      artifact = build_artifact(content:)
      yield attach_file(artifact:, io:)
      yield save_artifact(artifact)

      Success(artifact:)
    end

    private

    def read_content(io)
      content = io.read
      io.rewind
      Success(content)
    end

    def build_artifact(content:)
      input.fetch(:run).artifacts.new(
        run_item: input[:run_item],
        kind: input.fetch(:kind),
        sha256: Digest::SHA256.hexdigest(content),
        byte_size: content.bytesize,
        content_type: input[:content_type],
        source_url: input[:source_url],
        metadata: input.fetch(:metadata, {}),
        captured_at: Time.current
      )
    end

    def attach_file(artifact:, io:)
      artifact.file.attach(
        io:,
        filename: input.fetch(:filename),
        content_type: input[:content_type]
      )
      Success(artifact)
    end

    def save_artifact(artifact)
      return Success(artifact) if artifact.save

      fail_with(code: :validation_error, errors: artifact.errors.to_hash)
    end
  end
end
