# frozen_string_literal: true

require_relative 'errors/stats_data_not_available'
require_relative 'node/storage'

module JayAPI
  module Elasticsearch
    class Stats
      # Holds information about one of the nodes in the Elasticsearch cluster.
      class Node
        attr_reader :name

        # @param [String] name The name of the node.
        # @param [Hash] data Information about the node.
        def initialize(name, data)
          @name = name
          @data = data
        end

        # @return [JayAPI::Elasticsearch::Stats::Node::Storage] Storage
        #   information about the node.
        # @raise [JayAPI::Elasticsearch::Stats::Errors::StatsDataNotAvailable]
        #   If there is no storage information for the node.
        def storage
          @storage ||= ::JayAPI::Elasticsearch::Stats::Node::Storage.new(fs_totals)
        end

        private

        attr_reader :data

        # @return [Hash] Aggregated information about the +Node+'s
        #   filesystem.
        # @raise [JayAPI::Elasticsearch::Stats::Errors::StatsDataNotAvailable]
        #   If there is no filesystem information for the node.
        def fs_totals
          @fs_totals ||= data.dig('fs', 'total') || raise(
            ::JayAPI::Elasticsearch::Stats::Errors::StatsDataNotAvailable,
            "Filesystem data not available for node #{name}"
          )
        end
      end
    end
  end
end
