# frozen_string_literal: true

require 'active_support'
require 'active_support/json' # Needed because ActiveSupport 6 doesn't include it's own JSON module. 🤦
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/keys'
require 'elasticsearch'
require 'logging'

require_relative 'errors/elasticsearch_error'
require_relative 'async'
require_relative 'query_results'
require_relative 'response'
require_relative 'batch_counter'
require_relative 'search_after_results'

module JayAPI
  module Elasticsearch
    # Represents an Elasticsearch index. Allows data to be pushed to it one
    # record at a time or in batches of the specified size.
    class Index
      attr_reader :client, :index_name, :batch_size

      # Default type for documents indexed with the #index method.
      DEFAULT_DOC_TYPE = 'nested'

      # Supported document types (for the #index method)
      SUPPORTED_TYPES = [DEFAULT_DOC_TYPE, nil].freeze

      # :reek:ControlParameter (want to avoid the creating of the logger on method definition)
      # Creates a new instance of the class.
      # @param [JayAPI::Elasticsearch::Client] client The Elasticsearch Client object.
      # @param [String] index_name The name of the Elasticsearch index.
      # @param [Integer] batch_size The size of the batch. When this number of
      #   items are pushed into the index they are flushed to the
      #   Elasticsearch instance.
      # @param [Logging::Logger, nil] logger The logger object to use, if
      #   none is given a new one will be created.
      def initialize(client:, index_name:, batch_size: 100, logger: nil)
        @logger = logger || Logging.logger[self]

        @client = client
        @index_name = index_name
        @batch_size = batch_size

        @batch = []
      end

      # Pushes a record into the index. (This does not send the record to the
      # Elasticsearch instance, only puts it into the send queue).
      # @param [Hash] data The data to be pushed to the index.
      def push(data)
        @batch << { index: { _index: index_name, _type: 'nested', data: data } }
        flush! if @batch.size >= batch_size
      end

      # Sends a record to the Elasticsearch instance right away.
      # @param [Hash] data The data to be sent.
      # @param [String, nil] type The type of the document. When set to +nil+
      #   the decision is left to Elasticsearch's API. Which will normally
      #   default to +_doc+.
      # @return [Hash] A hash with information about the created document. An
      #   example of such Hash is:
      #
      #  {
      #    "_index" => "xyz01_unit_test",
      #    "_type" => "nested",
      #    "_id" => "SVY1mJEBQ5CNFZM8Lodt",
      #    "_version" => 1,
      #    "result" => "created",
      #    "_shards" => { "total" => 2, "successful" => 1, "failed" => 0 },
      #    "_seq_no" => 0,
      #    "_primary_term" => 1
      #  }
      #
      # For information on the contents of this Hash please see:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html#docs-index-api-response-body
      def index(data, type: DEFAULT_DOC_TYPE)
        raise ArgumentError, "Unsupported type: '#{type}'" unless SUPPORTED_TYPES.include?(type)

        client.index index: index_name, type: type, body: data
      end

      # Performs a query on the index.
      # For more information on how to build the query please refer to the
      # Elasticsearch DSL query:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
      # @param [Hash] query The query to perform.
      # @param [JayAPI::Elasticsearch::BatchCounter, nil] batch_counter Object keeping track of batches.
      # @param [Symbol, nil] type Type of query, at the moment either nil or :search_after.
      # @return [JayAPI::Elasticsearch::QueryResults] The query results.
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the
      #   query fails.
      def search(query, batch_counter: nil, type: nil)
        begin
          response = Response.new(client.search(index: index_name, body: query))
        rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest
          logger.error "The 'search' query is invalid: #{JSON.pretty_generate(query)}"
          raise
        end
        query_results(query, response, batch_counter, type)
      end

      # Sends whatever is currently in the send queue to the Elasticsearch
      # instance and clears the queue.
      def flush
        return unless @batch.any?

        flush!
      end

      # Returns the number of elements currently on the send queue.
      # @return [Integer] The number of items in the send queue.
      def queue_size
        @batch.size
      end

      # Delete the documents matching the given query from the Index.
      # For more information on how to build the query please refer to the
      # Elasticsearch DSL documentation:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html
      # @param [Hash] query The delete query
      # @param [Integer] slices Number of slices to cut the operation into for
      #   faster processing (i.e., run the operation in parallel)
      # @param [Boolean] wait_for_completion False if Elasticsearch should not
      #   wait for completion and perform the request asynchronously, true if it
      #   should wait for completion (i.e., run the operation asynchronously)
      # @return [Hash] A Hash that details the results of the operation
      # @example Returned Hash (with `wait_for_completion: true`):
      #     {
      #       took: 103,
      #       timed_out: false,
      #       total: 76,
      #       deleted: 76,
      #       batches: 1,
      #       version_conflicts: 0,
      #       noops: 0,
      #       retries: { bulk: 0, search: 0 },
      #       throttled_millis: 0,
      #       requests_per_second: 1.0,
      #       throttled_until_millis: 0,
      #       failures: []
      #     }
      # @example Returned Hash (with `wait_for_completion: false`):
      #     {
      #       task: "B5oDyEsHQu2Q-wpbaMSMTg:577388264"
      #     }
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the
      #   query fails.
      def delete_by_query(query, slices: nil, wait_for_completion: true)
        request_params = { index: index_name, body: query }.tap do |params|
          params.merge!(slices: slices) if slices
          params.merge!(wait_for_completion: false) unless wait_for_completion
        end

        client.delete_by_query(**request_params).deep_symbolize_keys
      end

      # Deletes asynchronously the documents matching the given query from the
      # Index.
      # For more information on how to build the query please refer to the
      # Elasticsearch DSL documentation:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html
      # @param [Hash] query The delete query
      # @param [Integer, String] slices Number of slices to cut the operation
      #   into for faster processing (i.e., run the operation in parallel). Use
      #   "auto" to make elasticsearch decide how many slices to divide into
      # @return [Concurrent::Promise] The eventual value returned from the single
      #   completion of the delete operation
      def delete_by_query_async(query, slices: nil)
        async.delete_by_query(query, slices: slices)
      end

      private

      attr_reader :logger, :batch

      # Flushes the current send queue to the Elasticsearch instance and
      # clears the queue.
      def flush!
        logger.info "Pushing data to Elasticsearch (#{batch.size} records)..."
        response = client.bulk body: batch

        handle_errors(response) if response['errors']

        logger.info 'Done'
        @batch = []
      end

      # @param [Hash] query The elastic search query.
      # @param [JayAPI::Elasticsearch::Response] response The response to the query.
      # @param [JayAPI::Elasticsearch::BatchCounter, nil] batch_counter Object keeping track of batches.
      # @param [Symbol, nil] type Type of query, at the moment either nil or :search_after.
      # @return [QueryResults]
      def query_results(query, response, batch_counter, type)
        (type == :search_after ? SearchAfterResults : QueryResults).new(
          index: self,
          query: query,
          response: response,
          batch_counter: BatchCounter.create_or_update(batch_counter, query, response.size)
        )
      end

      # Scans the Elasticsearch response in search for the first item that has
      # en erroneous state and raises an error including the error details.
      # @param [Hash] response The response returned by the Elasticsearch client.
      # @raise [Errors::ElasticsearchError] Is always raised.
      def handle_errors(response)
        error_item = response['items'].find { |item| item['index']['error'] }

        raise Errors::ElasticsearchError,
              "An error occurred when pushing the data to Elasticsearch:\n#{error_item['index']['error'].inspect}"
      end

      # @return [JayAPI::Elasticsearch::Async]
      def async
        @async ||= JayAPI::Elasticsearch::Async.new(self)
      end
    end
  end
end
