# frozen_string_literal: true

require 'forwardable'

module JayAPI
  module Elasticsearch
    # Lightweight wrapper around an Elasticsearch count response.
    #
    # It behaves like a numeric value for comparisons and arithmetic while
    # preserving access to the original response payload.
    class Count
      extend Forwardable

      include Comparable

      def_delegators :count, :to_i, :to_int

      # @param [Hash] data The raw Elasticsearch response that includes the
      #   +count+ value.
      def initialize(data)
        @data = data
      end

      # The count returned by Elasticsearch.
      # @return [Integer] The raw count value from the response payload.
      def count
        @count ||= data['count']
      end

      # Coerces another value so arithmetic operations can be performed with
      # the receiver.
      # @param [Numeric, #to_int] other The other operand.
      # @return [Array(Numeric, Integer)] A two-element array in the form
      #   expected by Ruby coercion.
      # @raise [TypeError] If +other+ cannot be coerced into an +Integer+.
      # :reek:FeatureEnvy :reek:ManualDispatch -- Not much that can be done here, since this is a coercion method.
      def coerce(other)
        if other.is_a?(Numeric)
          [other, to_int]
        elsif other.respond_to?(:to_int)
          [other.to_int, to_int]
        else
          raise TypeError, "#{other.class} cannot be coerced into Integer"
        end
      end

      # Compares this count with another numeric value.
      # @param [Numeric, #to_int] other The value to compare with.
      # @return [-1, 0, 1, nil] Comparison result, or +nil+ when the values are
      #   not comparable.
      # :reek:ManualDispatch -- Relies on the other object responding to +to_int+.
      def <=>(other)
        if other.is_a?(Numeric)
          to_int <=> other
        elsif other.respond_to?(:to_int)
          to_int <=> other.to_int
        else
          super
        end
      end

      # Adds another value to the receiver's count.
      # @param [Numeric, #to_int] other The value to add.
      # @return [Numeric] The arithmetic result.
      def +(other)
        other, this = coerce(other)
        this + other
      end

      # Subtracts another value from the receiver's count.
      # @param [Numeric, #to_int] other The value to subtract.
      # @return [Numeric] The arithmetic result.
      def -(other)
        other, this = coerce(other)
        this - other
      end

      # Multiplies the receiver's count by another value.
      # @param [Numeric, #to_int] other The value to multiply by.
      # @return [Numeric] The arithmetic result.
      def *(other)
        other, this = coerce(other)
        this * other
      end

      # Divides the receiver's count by another value.
      # @param [Numeric, #to_int] other The divisor.
      # @return [Numeric] The arithmetic result.
      def /(other)
        other, this = coerce(other)
        this / other
      end

      # @return [String] The count converted to a string.
      def to_s
        count.to_s
      end

      private

      attr_reader :data
    end
  end
end
