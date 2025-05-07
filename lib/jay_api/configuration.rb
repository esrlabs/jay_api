# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/indifferent_access'

require 'erb'
require 'forwardable'
require 'ostruct'
require 'yaml'

require_relative 'errors/configuration_error'

module JayAPI
  # Hold the configuration for Jay's API
  class Configuration < OpenStruct
    extend Forwardable

    def_delegators :deep_to_h, :with_indifferent_access

    # Loads the configuration from the given file.
    # @param [String] file_name The file from which to load the configuration.
    # @return [JayAPI::Configuration] The configuration for Jay's API.
    # @raise [Errno::ENOENT] If the given file cannot be found.
    # @raise [Psych::DisallowedClass] If the YAML contains a class other than
    #   Symbol
    def self.from_file(file_name)
      from_string(File.read(file_name))
    end

    # Loads the configuration from the given YAML string.
    # @param [String] yaml The YAML string containing the configuration.
    # @return [JayAPI::Configuration] The configuration for Jay's API
    # @raise [Psych::DisallowedClass] If the YAML contains a class other than
    #   Symbol
    def self.from_string(yaml)
      yaml = ERB.new(yaml).result
      config = YAML.safe_load(yaml, permitted_classes: [Symbol])

      unless config.is_a?(Hash)
        raise JayAPI::Errors::ConfigurationError.new(
          "Jay's configuration should be a set of key-value pairs.", yaml
        )
      end

      from_hash(config)
    end

    class << self
      private

      # Creates an instance of the class by parsing the given Hash.
      # Nested hashes are recursively parsed an new instances of the class are
      # created from them.
      # @param [Hash] hash The hash with the data.
      # @return [JayAPI::Configuration] An instance of the class created out of
      #   the given Hash.
      def from_hash(hash)
        new.tap do |configuration|
          hash.symbolize_keys.each do |key, value|
            configuration[key] = parsed_value(value)
          end
        end
      end

      # Takes a value and parses it in accordance to its type.
      # @param [Object] value The value to parse.
      # @return [JayAPI::Configuration, Array, Object] The parsed value.
      def parsed_value(value)
        case value
        when Hash
          from_hash(value)
        when Array
          value.map { |item| parsed_value(item) }
        else
          value
        end
      end
    end

    # Recursively converts the receiver into a standard Hash
    # @return [Hash] The result of the conversion.
    def deep_to_h
      to_h { |key, value| [key, value_for_h(value)] }
    end

    # @return [String] The configuration in the YAML format
    def to_yaml
      YAML.dump(deep_to_h.deep_stringify_keys)
    end

    private

    # Takes a value and transforms it in accordance to its type.
    # @param [Object] value The value to convert.
    #   * JayAPI::Configuration objects are transformed to hashes recursively.
    #   * Hashes are kept as Hashes but its values are transformed recursively.
    #   * Arrays are transformed recursively.
    #   * Any other value is left as is.
    # @return [Object] The converted value (or the same value if the method
    #   doesn't know how to convert it).
    def value_for_h(value)
      case value
      when self.class
        value.deep_to_h
      when Hash
        value.transform_values { |hash_value| value_for_h(hash_value) }
      when Array
        value.map { |element| value_for_h(element) }
      else
        value
      end
    end
  end
end
