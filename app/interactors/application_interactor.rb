# frozen_string_literal: true

# Shared Routeprint interactor behavior for contracts, transactions, and results.
class ApplicationInteractor < Yabi::BaseInteractor
  # Validates the declared input using the interactor's validation contract.
  #
  # @param validation_contract [Class, nil] contract class or nil when validation is skipped
  # @return [Dry::Monads::Result] validation result
  def validate_contract(validation_contract)
    return Success() unless validation_contract

    validation_contract.new.call(attributes_for_contract[:input])
  end

  # Logs a validation result and converts it to the application's failure shape.
  #
  # @param validation [Dry::Validation::Result, Hash] validation result or errors
  # @return [Dry::Monads::Failure] validation failure
  def log_warning_and_return_failure(validation)
    errors = validation.respond_to?(:errors) ? validation.errors.to_h : validation

    fail_with(code: :validation_error, errors:)
  end

  # Executes a block and converts selected exceptions into monadic results.
  #
  # @param exceptions [Array<Class>] exception classes to capture
  # @param on_success [Proc] success result mapper
  # @param on_error [Proc] exception result mapper
  # @yieldreturn [Object] block result
  # @return [Dry::Monads::Result] mapped block result
  def safe_call(*exceptions, on_success: ->(s) { Success(s) }, on_error: ->(e) { Failure(e) }, &)
    if exceptions.any?
      Try(*exceptions, &).to_result.either(on_success, on_error)
    else
      Try(&).to_result.either(on_success, on_error)
    end
  end

  private

  def fail_with(code:, errors: {})
    Failure(code:, errors:)
  end
end
