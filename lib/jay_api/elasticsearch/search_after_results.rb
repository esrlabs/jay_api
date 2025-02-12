# frozen_string_literal: true

require_relative 'errors/search_after_error'
require_relative 'query_results'

module JayAPI
  module Elasticsearch
    # A QueryResults class for the 'search_after' type of query.
    # See more: https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html
    class SearchAfterResults < QueryResults
      # The default 'from' attribute for the 'search_after' query. See the link for more details.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html#:~:text=(default)%20or-,%2D1,-.
      DEFAULT_FROM = -1

      # @return [true] It should always be assumed that there are more results when
      #   using 'search_after' parameter
      def more?
        true
      end

      # Fetches the next batch of documents.
      # @return [JayAPI::Elasticsearch::QueryResults] A new instance of the
      #   QueryResults that contains the next batch of documents fetched from
      #   Elasticsearch.
      def next_batch
        index.search(adapt_query, batch_counter: batch_counter, type: :search_after)
      end

      private

      # @raise [JayAPI::Elasticsearch::Errors::SearchAfterError]
      def raise_sort
        raise(
          JayAPI::Elasticsearch::Errors::SearchAfterError,
          "'sort' attribute must be specified in the query when using 'search_after' parameter"
        )
      end

      # @return [String] the 'sort' attribute of the last Doc hash in the batch.
      # @raise [JayAPI::Elasticsearch::Errors::SearchAfterError] If 'sort' is not found in the Doc.
      def sort
        @sort ||= last['sort'] || raise_sort
      end

      # Adapts the query for the next batch.
      # * The 'from' attribute must be set to a special value.
      # * The 'search_after' attribute must contain the 'sort' attribute of the
      #   last received Doc.
      # @return [Hash]
      def adapt_query
        super.tap do |modified_query|
          modified_query[:from]         = DEFAULT_FROM
          modified_query[:search_after] = sort
        end
      end
    end
  end
end
