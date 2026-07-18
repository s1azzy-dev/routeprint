module Imports
  # Dispatches a run item to the adapter for its configured source.
  #
  # @example
  #   Imports::SourceProcessor.call(input: { run:, item: })
  # @param input [Hash] import run and run item
  class SourceProcessor < ApplicationInteractor
    option :input
    option :airport_processor, default: -> { Imports::OurAirports::Airports::Processor }
    option :country_catalog_processor, default: -> { Imports::Countries::Processor }

    class ValidationContract < ApplicationContract
      params do
        required(:run).filled(type?: Imports::Run)
        required(:item).filled(type?: Imports::RunItem)
      end
    end

    def call
      run = input.fetch(:run)
      case run.source.key
      when "ourairports_airports" then airport_processor.call(input:)
      when "country_catalog" then country_catalog_processor.call(input:)
      else Failure(code: :source_processor_not_implemented, errors: { source_key: [ run.source.key ] })
      end
    end
  end
end
