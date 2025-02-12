# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'forwardable'

require_relative 'errors/end_of_query_results_error'
require_relative 'batch_counter'

module JayAPI
  module Elasticsearch
    # Represents the results of an Elasticsearch query.
    # It provides a facade in front of the returned Hash and allows more
    # results to be fetched dynamically.
    class QueryResults
      extend Forwardable

      attr_reader :index, :query, :response, :batch_counter

      def_delegators :batch_counter, :batch_size, :start_next
      def_delegators :response, :hits, :total, :size, :count, :first, :last, :any?, :empty?, :aggregations

      # Creates a new instance of the class.
      # @param [JayAPI::Elasticsearch::Index] index The Elasticsearch
      #   index used to perform the query.
      # @param [Hash] query The query that produced the results.
      # @param [JayAPI::Elasticsearch::Results] response An object containing Docs retrieved from Elasticsearch.
      # @param [JayAPI::Elasticsearch::BatchCounter] batch_counter An object keeping track of the current batch.
      def initialize(index:, query:, response:, batch_counter: nil)
        @index = index
        @query = query.with_indifferent_access
        @response = response
        @batch_counter = batch_counter
      end

      # @return [Boolean] True if there are still more documents matched by the
      #   query and a call to next_batch can be performed.
      def more?
        start_next < total
      end

      # Calls the given block for every document in the QueryResults object or
      # returns an Enumerator with all the documents if no block is given.
      # @yield [Hash] Each document in the current QueryResults object.
      # @return [Enumerator, Array] An enumerator with all the objects in the
      #   QueryResults object if no block is given, or an array of all the
      #   documents in the QueryResults object.
      def each(&block)
        hits.each(&block)
      end

      # Allows the entire set of documents to be iterated in batches.
      #
      #  - If the method is invoked with a block, the given block will be called
      #    for every document in the +QueryResults+ object. Upon reaching the
      #    end of the collection the next batch will be requested and the block
      #    will be called again for each of the documents in the next batch, the
      #    process will continue until there are no more documents. At the end,
      #    the last batch of documents will be returned.
      #
      #  - If the method is called without a block an +Enumerator+ object will
      #    be returned. Said +Enumerator+ can be used to iterate through the
      #    whole set of documents. The +#all+ method will take care of fetching
      #    them in batches and yielding them to the enumerator.
      #
      # @yield [Hash] Each document in the current QueryResults object.
      # @return [JayAPI::Elasticsearch::QueryResults, Enumerator] If a block is
      #   given the object with the last batch of documents (can be the receiver
      #   if there is only one batch) will be returned. If no block is given
      #   an +Enumerator+ will be returned.
      def all(&block)
        return enum_for(:all) { total - start_current } unless block

        data = self

        loop do
          data.each(&block)
          break unless data.more? && data.any?

          data = data.next_batch
        end

        data
      end

      # Fetches the next batch of documents.
      # @return [JayAPI::Elasticsearch::QueryResults] A new instance of the
      #   QueryResults that contains the next batch of documents fetched from
      #   Elasticsearch.
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the
      #   query fails.
      def next_batch
        raise Errors::EndOfQueryResultsError unless more?

        modified_query = adapt_query
        index.search(modified_query, batch_counter: batch_counter)
      end

      private

      def_delegators :batch_counter, :start_current

      def adapt_query
        query.dup.tap do |modified_query|
          modified_query[:size] = batch_size
          modified_query[:from] = start_next
        end
      end
    end
  end
end
