# frozen_string_literal: true

require 'forwardable'

module JayAPI
  module Elasticsearch
    # The `Response` class encapsulates and processes the results received
    # from an Elasticsearch query. It provides a uniform interface for accessing
    # and working with the retrieved data.
    class Response
      extend Forwardable

      # @!attribute [r] raw_response
      #   @return [Hash] The raw results data returned from Elasticsearch
      attr_reader :raw_response

      def_delegators :hits, :size, :count, :first, :last, :any?, :empty?

      # @param [Hash] raw_response The raw results data from Elasticsearch
      def initialize(raw_response)
        @raw_response = raw_response
      end

      # @return [Hash, nil] The aggregations present in the current result set
      #   (if there are any).
      def aggregations
        @aggregations ||= raw_response['aggregations']
      end

      # The actual "hits" results from the Elasticsearch response
      # @return [Array<Hash>]
      def hits
        @hits ||= raw_response.dig('hits', 'hits') || []
      end

      # The total count of results that match the query criteria
      # @return [Integer]
      def total
        @total ||= raw_response.dig('hits', 'total', 'value') || hits.size
      end
    end
  end
end
