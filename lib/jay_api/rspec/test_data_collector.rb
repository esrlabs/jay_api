# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'rspec'
require 'rspec/core/formatters'
require 'rspec/core/configuration'

require_relative '../elasticsearch/client_factory'
require_relative '../elasticsearch/index'
require_relative '../elasticsearch/time'
require_relative '../id_builder'
require_relative 'configuration'
require_relative 'git'

module JayAPI
  module RSpec
    # Collects RSpec Test Data and pushes it to Jay's Elasticsearch backend.
    class TestDataCollector
      include JayAPI::Elasticsearch::Time
      include JayAPI::RSpec::Git

      DEFAULT_BATCH_SIZE = 100

      # Meta-dara keys that can be used to annotate requirements in tests.
      REQUIREMENTS_KEYS = %i[requirements refs].freeze

      ::RSpec::Core::Formatters.register self, :start, :close, :example_finished

      # Executed by RSpec during initialization.
      # Sets the +@push_enabled+ instance variable according to configuration.
      def initialize(_output)
        @push_enabled = configuration.push_enabled # When the push is disabled the class behaviour is inhibited.
      end

      # Called by RSpec at the beginning of the test run. If the push is enabled
      # the method initializes the Elasticsearch::Index instance. This is done
      # so that, if it cannot be initialized the tests will fail right away and
      # not after execution.
      def start(_notification)
        return unless push_enabled

        elasticsearch_index
      end

      # Called by RSpec when an example is finished. The method extracts all the
      # information from the given notification and creates a data +Hash+ to
      # push to Elasticsearch.
      # @param [RSpec::Core::Notifications::ExampleNotification] notification
      #   The +Notification+ object passed by RSpec.
      def example_finished(notification)
        return unless push_enabled

        example = notification.example
        identifier = example.full_description
        ex_result = example.execution_result
        metadata = example.metadata

        data = {
          test_env: {
            build_number: ENV['BUILD_NUMBER'],
            build_job_name: ENV['JOB_NAME'],
            repository: git_remote.presence,
            revision: git_revision.presence,
            hostname: hostname
          },
          test_case: {
            name: identifier,
            started_at: format_time(ex_result.started_at),
            finished_at: format_time(ex_result.finished_at),
            runtime: ex_result.run_time,
            id_long: identifier,
            id: build_short_id(identifier),
            location: metadata[:location],
            requirements: requirements_from(metadata),
            expectation: example.description,
            result: translate_result(ex_result.status),
            exception: ex_result.exception&.message&.strip
          }
        }

        elasticsearch_index.push(data)
      end

      # Executed by RSpec at the end of the test run. If the push is enabled,
      # any test cases still being held in the Elasticsearch buffer are flushed.
      def close(_notification)
        return unless push_enabled

        elasticsearch_index.flush
      end

      private

      attr_reader :push_enabled

      # @return [Hash] The configuration set for Elasticsearch as a hash. If no
      #   value has been set for the batch size a reasonable default is set.
      # @raise [JayAPI::Errors::ConfigurationError] If no configuration for
      #   Elasticsearch has been provided.
      def elasticsearch_config
        @elasticsearch_config ||= configuration.elasticsearch.tap do |config|
          unless config
            raise JayAPI::Errors::ConfigurationError,
                  'No Elasticsearch configuration provided for the JayAPI::RSpec module.'
          end
        end.to_h
      end

      # @return [JayAPI::Elasticsearch::Client] The +Elasticsearch::Client+
      #   object that the importer uses to initialize the +Elasticsearch::Index+
      #   class.
      def client
        @client ||= JayAPI::Elasticsearch::ClientFactory.new(**elasticsearch_config).create
      end

      # @return [Hash] A Hash with the required parameters for the
      #   +Elasticsearch::Index+ class
      def index_params
        @index_params ||= {
          index_name: elasticsearch_config.delete(:index_name),
          batch_size: elasticsearch_config.delete(:batch_size) || DEFAULT_BATCH_SIZE,
          client: client
        }
      end

      # @return [JayAPI::Elasticsearch::Index] An +Elasticsearch::Index+
      #   instance that can be used to push data or search for it.
      # @raise [ArgumentError] If any of the needed parameters to initialize the
      #   Elasticsearch Index is missing.
      def elasticsearch_index
        @elasticsearch_index ||= JayAPI::Elasticsearch::Index.new(**index_params)
      end

      # @return [JayAPI::Configuration] The configuration for the JayAPI::RSpec
      #   module
      # @raise [JayAPI::Errors::ConfigurationError] If the module hasn't been
      #   configured yet.
      def configuration
        @configuration ||= JayAPI::RSpec.configuration
      end

      # Builds a short identifier for the Test Case from its long identifier.
      # @param [String] long_id The Long Identifier of the Test Case
      # @return [String] The short identifier for the Test Case.
      def build_short_id(long_id)
        JayAPI::IDBuilder.new(test_case_id: long_id, project: project).short_id
      end

      # @return [String] The name of the configured project.
      def project
        @project ||= configuration.project
      end

      # Translates the given test result
      # @param [Symbol] result The test result (provided by RSpec)
      # @return [String] The translated result
      def translate_result(result)
        case result
        when :passed then 'pass'
        when :failed then 'fail'
        when :pending then 'skip'
        else 'error'
        end
      end

      # @return [String] The name of the computer running the tests
      def hostname
        @hostname ||= `hostname`.chomp
      end

      # Extracts the requirements from the given meta-data. The methods checks
      # the given meta-data hash and creates an array with all the requirements
      # found in either of the keys which can contain them.
      #
      # If more than one key contains requirements they are put together into a
      # single array. If none of the keys have requirements +nil+ is returned.
      #
      # @param [Hash] metadata The meta-data Hash (normally comes from RSpec).
      # @return [Array<Object>, nil] An array with all the requirements found
      #   in the given meta-data Hash or +nil+ if none was found.
      def requirements_from(metadata)
        REQUIREMENTS_KEYS.each_with_object([]) do |key, array|
          array.concat(Array(metadata[key]))
        end.presence
      end
    end
  end
end
