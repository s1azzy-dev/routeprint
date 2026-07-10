module Imports
  class CaptureArtifact < ApplicationInteractor
    option :input

    def call
      io = input.fetch(:io)
      content = io.read
      io.rewind

      artifact = input.fetch(:run).artifacts.new(
        run_item: input[:run_item],
        kind: input.fetch(:kind),
        sha256: Digest::SHA256.hexdigest(content),
        byte_size: content.bytesize,
        content_type: input[:content_type],
        source_url: input[:source_url],
        metadata: input.fetch(:metadata, {}),
        captured_at: Time.current
      )
      artifact.file.attach(
        io:,
        filename: input.fetch(:filename),
        content_type: input[:content_type]
      )

      return fail_with(code: :validation_error, errors: artifact.errors.to_hash) unless artifact.save

      Success(artifact:)
    rescue KeyError => error
      fail_with(code: :validation_error, errors: { input: [ error.message ] })
    end
  end
end
