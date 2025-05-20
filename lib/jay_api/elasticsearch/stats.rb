# frozen_string_literal: true

require_relative 'stats/index'
require_relative 'stats/indices'

module JayAPI
  module Elasticsearch
    # This class provides access to Elasticsearch's Cluster Statistic API.
    class Stats
      attr_reader :transport_client, :logger

      # @param [Elasticsearch::Transport::Client] transport_client The transport
      #   client to use to make requests to the cluster.
      def initialize(transport_client)
        @transport_client = transport_client
      end

      # @return [JayAPI::Elasticsearch::Stats::Indices] Information about the
      #   indices that exist in the Elasticsearch cluster.
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the request
      #   to the Statistics API endpoint fails.
      def indices
        # DO NOT MEMOIZE! Leave it to the caller.
        ::JayAPI::Elasticsearch::Stats::Indices.new(indices_stats['indices'])
      end

      private

      # @return [Hash] The Hash with the index-related statistics returned by
      #   the Elasticsearch cluster.
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the
      #   request fails.
      def indices_stats
        # DO NOT MEMOIZE! Leave it to the caller.
        transport_client.indices.stats
      end
    end
  end
end
