module Imports
  # Dispatches a run item to the adapter for its configured source.
  #
  # @example
  #   Imports::SourceProcessor.call(input: { run:, item: })
  # @param input [Hash] import run and run item
  class SourceProcessor < ApplicationInteractor
    option :input
    option :processor, default: -> { Imports::OurAirports::Airports::Processor }

    class ValidationContract < ApplicationContract
      params do
        required(:run).filled(type?: Imports::Run)
        required(:item).filled(type?: Imports::RunItem)
      end
    end

    def call
      run = input.fetch(:run)
      if run.source.key == "ourairports_airports"
        return processor.call(input:)
      end

      Failure(
        code: :source_processor_not_implemented,
        errors: { source_key: [ run.source.key ] }
      )
    end
  end
end
