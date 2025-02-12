# frozen_string_literal: true

require_relative '../configuration'
require_relative '../errors/configuration_error'

module JayAPI
  # A module that contains the classes and method needed to interact with RSpec
  # data (test cases, test results, etc).
  module RSpec
    # @return [JayAPI::Configuration] The current configuration for JayAPI::RSpec
    # @raise [JayAPI::Errors::ConfigurationError] If the module hasn't been
    #   configured yet.
    def self.configuration
      unless @configuration
        raise JayAPI::Errors::ConfigurationError,
              'No configuration has been set for the JayAPI::RSpec module. ' \
              'Please call JayAPI::RSpec.configure to load/create configuration.'
      end

      @configuration
    end

    # Called to configure the JayAPI::RSpec module.
    # @yield [Class] Yields +JayAPI::Configuration+ (the class itself), on it
    #   the yielded block can call either, +new+, +from_string+ or +from_file+
    #   to create the configuration.
    # @yieldreturn [JayAPI::Configuration] The block should return an instance
    #   of the +JayAPI::Configuration+ class with the configuration for the
    #   module.
    # @raise [JayAPI::Errors::ConfigurationError] If the block returns anything
    #   but an instance of +JayAPI::Configuration+ or one of its subclasses.
    def self.configure
      configuration = yield JayAPI::Configuration

      return unless configuration

      unless configuration.is_a?(JayAPI::Configuration)
        raise JayAPI::Errors::ConfigurationError,
              'Expected a JayAPI::Configuration or a subclass. ' \
              "Got a #{configuration.class} instead."
      end

      @configuration = configuration
    end
  end
end
