# frozen_string_literal: true

require_relative 'wait_strategy'

module JayAPI
  module Abstract
    # A geometric wait strategy implementation of the WaitStrategy abstract class.
    # This strategy uses a geometrically increasing wait interval between retries.
    # The wait interval is exponentially increased based on the number of attempts made,
    # making it suitable for scenarios where a rapidly increasing delay is preferred.
    #
    # Inherits from WaitStrategy and overrides the wait_time method to provide a geometrically increasing waiting time.
    class GeometricWait < WaitStrategy
      private

      attr_writer :calls_count

      # Determines the time to wait before the next retry in a geometric manner.
      # The wait time increases exponentially with each call, calculated as wait_interval
      # raised to the power of call number.
      # @return [Integer] The exponentially increasing time to wait in seconds.
      def wait_time
        self.calls_count += 1
        wait_interval**calls_count
      end

      # Tracks the number of calls made to the wait_time method.
      # This count is used to calculate the geometrically increasing wait time.
      # @return [Integer] The number of times the wait_time method has been called.
      def calls_count
        @calls_count ||= 0
      end
    end
  end
end
