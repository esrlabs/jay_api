# frozen_string_literal: true

require 'logging'

# A custom logging appender that collects log messages into an array.
# This can be useful in testing environments where you need to inspect
# the log messages generated during the execution of code.
#
# @example
#   logger = Logging.logger['test_logger']
#   array_appender = ArrayAppender.new('array')
#   logger.add_appenders(array_appender)
#   logger.info "This is a test log message."
#   logger.info "This is on the next line"
#   puts array_appender.logs # => ["This is a test log message.", "This is on the next line"]
#   puts array_appender.to_s # => "This is a test log message.\nThis is on the next line"
class ArrayAppender < Logging::Appender
  # @return [Array<String>] The collected log messages.
  attr_reader :logs

  # @param args [Array] Arguments passed to the superclass initializer.
  def initialize(*args)
    super
    @logs = []
  end

  # Returns a string representation of all logged messages, joined by newlines.
  # @return [String] The logged messages as a single string.
  def to_s
    logs.join("\n")
  end

  # Writes a logging event to the appender.
  # @param event [Logging::LogEvent] The event to log.
  def write(event)
    @logs << event.data
  end
end
