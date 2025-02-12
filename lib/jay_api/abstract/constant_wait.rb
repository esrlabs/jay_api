# frozen_string_literal: true

require_relative 'wait_strategy'

module JayAPI
  module Abstract
    # A constant wait strategy implementation of the WaitStrategy abstract class.
    # This strategy uses a fixed wait interval between retries. The wait interval does not change
    # regardless of the number of attempts made. It is suitable for scenarios where a constant
    # delay is preferred over an increasing delay.
    #
    # Inherits from WaitStrategy and overrides the wait_time method to provide a linear waiting time.
    class ConstantWait < WaitStrategy
      alias wait_time wait_interval
    end
  end
end
