# frozen_string_literal: true

class MinimalRspecFormatter
  RSpec::Core::Formatters.register self, :dump_failures, :dump_summary

  def initialize(output)
    @output = output
  end

  def dump_failures(notification)
    return if notification.failure_notifications.empty?

    @output.puts
    @output.puts "Failures:"
    notification.failure_notifications.each_with_index do |failure, index|
      @output.puts failure.fully_formatted(index + 1)
    end
  end

  def dump_summary(notification)
    summary = [
      "#{notification.example_count} examples",
      "#{notification.failure_count} failures"
    ]
    summary << "#{notification.pending_count} pending" if notification.pending_count.positive?

    @output.puts summary.join(", ")
  end
end
