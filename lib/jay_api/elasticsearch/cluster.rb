# frozen_string_literal: true

require 'forwardable'

require_relative 'mixins/retriable_requests'

module JayAPI
  module Elasticsearch
    # Represents the Elasticsearch cluster and provides access to
    # cluster-level APIs.
    class Cluster
      extend Forwardable

      def_delegator :cluster_client, :health

      attr_reader :transport_client

      # @param [Elasticsearch::Transport::Client] transport_client The transport
      #   client to use to make requests to the cluster.
      def initialize(transport_client)
        @transport_client = transport_client
      end

      private

      # @return [Elasticsearch::API::Cluster::ClusterClient] The client used to
      #   access cluster-related information.
      def cluster_client
        @cluster_client ||= transport_client.cluster
      end
    end
  end
end
