# frozen_string_literal: true

require_relative 'error'

module JayAPI
  module Errors
    # An error to be raised when there is an issue with the configuration of
    # one of Jay's modules.
    class ConfigurationError < JayAPI::Errors::Error
      attr_reader :source_string

      # Creates a new instance of the class.
      # @param [String] message The error message
      # @param [String] source_string The string from which the configuration
      #   was loaded.
      def initialize(message, source_string = nil)
        @source_string = source_string
        super(message)
      end
    end
  end
end
