# frozen_string_literal: true

require 'jay_api/elasticsearch/cluster'

RSpec.describe JayAPI::Elasticsearch::Cluster do
  subject(:cluster) { described_class.new(transport_client) }

  let(:cluster_client) do
    instance_double(
      Elasticsearch::API::Cluster::ClusterClient,
      health: transport_response
    )
  end

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client,
      cluster: cluster_client
    )
  end

  describe '#health' do
    subject(:method_call) { cluster.health }

    let(:transport_response) do
      {
        'cluster_name' => 'xyz01_cluster',
        'status' => 'green',
        'timed_out' => false,
        'number_of_nodes' => 7,
        'number_of_data_nodes' => 4,
        'discovered_master' => true,
        'active_primary_shards' => 646,
        'active_shards' => 2182,
        'relocating_shards' => 0,
        'initializing_shards' => 0,
        'unassigned_shards' => 0,
        'delayed_unassigned_shards' => 0,
        'number_of_pending_tasks' => 0,
        'number_of_in_flight_fetch' => 0,
        'task_max_waiting_in_queue_millis' => 0,
        'active_shards_percent_as_number' => 100.0
      }
    end

    it 'gets the ClusterClient from the given TransportClient' do
      expect(transport_client).to receive(:cluster)
      method_call
    end

    it 'forwards the call to the Elasticsearch cluster client' do
      expect(cluster_client).to receive(:health)
      method_call
    end

    it 'directly returns the response' do
      expect(method_call).to be(transport_response)
    end
  end
end
