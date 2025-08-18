# frozen_string_literal: true

require 'concurrent/promise'
require 'forwardable'

require_relative 'errors/query_execution_error'
require_relative 'errors/query_execution_failure'
require_relative 'tasks'

module JayAPI
  module Elasticsearch
    # Provides functionality to perform asynchronous operations on an
    # elasticsearch index. For more information:
    # https://ruby-concurrency.github.io/concurrent-ruby/1.3.4/Concurrent
    class Async
      extend Forwardable

      attr_reader :index

      def_delegators :index, :index_name

      # @param [JayAPI::Elasticsearch::Indexable] index The elasticsearch
      #   index or indexes on which to execute asynchronous operations
      def initialize(index)
        @index = index
      end

      # Deletes asynchronously the documents matching the given query from the
      # Index.
      # @see JayAPI::Elasticsearch::Index#delete_by_query for more info
      # @param [Hash] query The delete query
      # @param [Integer, String] slices Number of slices to cut the operation
      #   into for faster processing (i.e., run the operation in parallel). Use
      #   "auto" to make elasticsearch decide how many slices to divide into
      # @return [Concurrent::Promise] The eventual value returned from the
      #   single completion of the delete operation
      # @raise [Errors::QueryExecutionError] If executing the query results in
      #   errors
      # @raise [Errors::QueryExecutionFailure] If executing the query results in
      #   failures
      def delete_by_query(query, slices: 5)
        Concurrent::Promise.execute do
          async_response = index.delete_by_query(query, slices: slices, wait_for_completion: false)
          result = tasks.by_id(async_response[:task])
          validate_result(result)
          result
        end
      end

      private

      # @param [Hash] result The operation result to be validated
      # @raise [Errors::QueryExecutionError] If executing the query results in
      #   errors
      # @raise [Errors::QueryExecutionFailure] If executing the query results in
      #   failures
      def validate_result(result)
        raise Errors::QueryExecutionError, "Errors on index '#{index_name}':\n #{result[:error]}" if result[:error]

        failures = result&.dig(:response, :failures)
        return if failures.nil? || failures.empty?

        raise Errors::QueryExecutionFailure, "Failures on index '#{index_name}':\n #{failures}"
      end

      # @return [JayAPI::Elasticsearch::Tasks]
      def tasks
        @tasks ||= JayAPI::Elasticsearch::Tasks.new(client: index.client)
      end
    end
  end
end
