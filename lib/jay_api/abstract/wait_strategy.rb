# frozen_string_literal: true

module JayAPI
  module Abstract
    # Abstract base class for implementing different waiting strategies.
    # This class provides a framework for implementing a strategy that dictates how long to wait
    # before retrying an operation, typically used in situations where an operation might need to be
    # retried multiple times (like network requests, etc.)
    #
    # @abstract Subclass and override {#wait_time} to implement a custom WaitStrategy.
    class WaitStrategy
      attr_reader :wait_interval

      # @param [Integer] wait_interval The initial time to wait before retrying.
      # @param [Logging::Logger] logger The logger to be used for logging wait times, defaults to stdout.
      def initialize(wait_interval:, logger: nil)
        @wait_interval = wait_interval
        @logger = logger || Logging.logger($stdout)
      end

      # Executes the wait strategy.
      # Logs the waiting time and pauses the execution for the determined wait time.
      def wait
        wait_time.tap do |wait_time|
          logger.info("Sleeping: #{format('%.2f', wait_time)} s")
          Kernel.sleep(wait_time)
        end
      end

      private

      attr_reader :logger

      # Determines the time to wait before the next retry.
      # This method must be implemented by subclasses.
      # @raise [NotImplementedError] if the method is not overridden in a subclass.
      # @return [Integer] The time to wait in seconds.
      def wait_time
        raise(NotImplementedError, "#{self.class} must implement the #{__method__} method")
      end
    end
  end
end
