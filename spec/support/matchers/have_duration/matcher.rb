# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'rspec/matchers/dsl'

module Support
  module Matchers
    # :reek:IrresponsibleModule (no descriptive comment here needed)
    module HaveDuration
      # Custom RSpec matcher to verify that the execution time of a given block of code
      # falls within an expected range or is close to a target time within a tolerance.
      #
      # @example Using the `have_duration` matcher with a range
      #   expect { some_process }.to have_duration(1..2.seconds)
      #
      # @example Using the `have_duration` matcher with within.of syntax
      #   expect { some_process }.to have_duration(within(0.2).of(1.second))
      class Matcher
        extend RSpec::Matchers::DSL

        attr_reader :expected, :elapsed_time

        # @param expected [Range, Matcher] The expected execution time range or 'within.of' matcher.
        def initialize(expected)
          @expected = expected
        end

        # Ths matcher must be called with a block.
        # @return [TrueClass] Always return true.
        def supports_block_expectations?
          true
        end

        # The matcher that measures time for a process to finish should only be allowed
        # to take blocks.
        # @return [TrueClass] Always return false.
        def supports_value_expectations?
          false
        end

        # Checks if the block's execution time meets the expectation.
        # @param block [Proc] The block of code to measure.
        # @return [Boolean] True if the block's execution time matches the expectation.
        def matches?(block)
          start_time = Time.now
          block.call
          self.elapsed_time = Time.now - start_time
          # rubocop:disable Style/CaseEquality: `===` allows matching `elapsed_time` with `expected` as a range or matcher.
          # Unlike `==`, `===` provides the necessary flexibility for diverse comparisons in this context.
          expected === elapsed_time
          # rubocop:enable Style/CaseEquality
        end

        # Provides a failure message.
        # @return [String] A message indicating why the matcher failed.
        def failure_message
          "expected block to execute #{range}, but executed in #{elapsed_time} seconds"
        end

        # Describes the matcher.
        # @return [String] A description of the matcher.
        def description
          "have execution time #{range}"
        end

        private

        attr_writer :expected, :elapsed_time

        # Formats the range or expectation for display.
        # @return [String] A string describing the expected range or condition.
        def range
          return "within #{expected}" if expected.is_a?(Range)

          expected.description
        end
      end

      # :reek:UtilityFunction This method is in a module already
      # @param [Range, Matcher] time The expected execution time range or 'within.of' matcher.
      # @return [Support::Matchers::HaveDuration::Matcher]
      def have_duration(time)
        Support::Matchers::HaveDuration::Matcher.new(time)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Support::Matchers::HaveDuration
end
