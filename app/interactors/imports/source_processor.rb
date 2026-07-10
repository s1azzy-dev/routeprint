module Imports
  class SourceProcessor < ApplicationInteractor
    option :input

    def call
      run = input.fetch(:run)
      if run.source.key == "ourairports_airports"
        return Imports::OurAirports::Airports::Processor.call(input:)
      end

      Failure(
        code: :source_processor_not_implemented,
        errors: { source_key: [ run.source.key ] }
      )
    end
  end
end
