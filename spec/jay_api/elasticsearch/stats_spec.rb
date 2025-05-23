# frozen_string_literal: true

require 'elasticsearch/transport/transport/errors'
require 'jay_api/elasticsearch/stats'

RSpec.describe JayAPI::Elasticsearch::Stats do
  subject(:stats) { described_class.new(transport_client) }

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client
    )
  end

  describe '#indices' do
    subject(:method_call) { stats.indices }

    let(:stats_hash) do
      {
        '_all' => {
          'total' => {
            'store' => {
              'size_in_bytes' => 830_124_136,
              'reserved_in_bytes' => 0
            }
          }
        },
        'indices' => {
          'xyz01_integration_test' => {
            'uuid' => 'OXRb8_IYTseG2epNa9Ls3g'
          },
          'xyz01_unit_tests' => {
            'uuid' => 'hxDdhi-3TFSndxhLesspFw'
          },
          '.kibana_views' => {
            'uuid' => 'pr-VjrPARlG3lAoAfPqNog'
          },
          'xyz02_manual_verification' => {
            'uuid' => 'uaZ_kKQuSM-HaKH_LcI7BQ'
          },
          '.backup' => {
            'uuid' => 'N7TZOstjRHu8mTwsLZuQ5w'
          }
        }
      }
    end

    let(:indices_client) do
      instance_double(
        Elasticsearch::API::Indices::IndicesClient,
        stats: stats_hash
      )
    end

    let(:indices) do
      instance_double(
        JayAPI::Elasticsearch::Stats::Indices
      )
    end

    let(:expected_indices_data) do
      {
        'xyz01_integration_test' => {
          'uuid' => 'OXRb8_IYTseG2epNa9Ls3g'
        },
        'xyz01_unit_tests' => {
          'uuid' => 'hxDdhi-3TFSndxhLesspFw'
        },
        '.kibana_views' => {
          'uuid' => 'pr-VjrPARlG3lAoAfPqNog'
        },
        'xyz02_manual_verification' => {
          'uuid' => 'uaZ_kKQuSM-HaKH_LcI7BQ'
        },
        '.backup' => {
          'uuid' => 'N7TZOstjRHu8mTwsLZuQ5w'
        }
      }
    end

    before do
      allow(transport_client).to receive(:indices).and_return(indices_client)
      allow(JayAPI::Elasticsearch::Stats::Indices).to receive(:new).and_return(indices)
    end

    it "requests the indices' statistics from the Elasticsearch cluster" do
      expect(transport_client).to receive(:indices)
      expect(indices_client).to receive(:stats)
      method_call
    end

    context 'when the API request fails' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Unauthorized,
          'Authentication failed'
        ]
      end

      before do
        allow(indices_client).to receive(:stats).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    it 'creates an instance of JayAPI::Elasticsearch::Stats::Indices and passes the indices data to it' do
      expect(JayAPI::Elasticsearch::Stats::Indices)
        .to receive(:new).with(expected_indices_data)

      method_call
    end

    it 'returns the instance of JayAPI::Elasticsearch::Stats::Indices' do
      expect(method_call).to be(indices)
    end
  end

  describe '#nodes' do
    subject(:method_call) { stats.nodes }

    let(:stats_hash) do
      {
        '_nodes' => { 'total' => 6, 'successful' => 6, 'failed' => 0 },
        'cluster_name' => '130592744203',
        'nodes' => {
          'Q9CAvRyRSBSBV3mxxbnPjQ' => { 'name' => '3be27c55fbd0bea8278c8e67f5e0dafa' },
          'ntd-0MYVRe-PnPSAH6jDDg' => { 'name' => '7aa07fa030f7e9ac302e7898fd400ded' },
          'MVSLeteKR_aiLjccChNYpA' => { 'name' => '443b4912dfc7c104afa8074e62246c22' },
          'uUZyFyxuThaHzsjmFRTxXw' => { 'name' => '30512cbcb29eeba7b854ef4f4663f42d' },
          'cNvDkFDWQ2miz5MvMmmVZg' => { 'name' => '9703b4532fa4f05e9fb305722bec0623' },
          '4Yk4GeazTE6gSId3OuOV1A' => { 'name' => 'ef6f30de3e7d26567960e0247026c2b8' }
        }
      }
    end

    let(:nodes_client) do
      instance_double(
        Elasticsearch::API::Nodes::NodesClient,
        stats: stats_hash
      )
    end

    let(:nodes) do
      instance_double(
        JayAPI::Elasticsearch::Stats::Nodes
      )
    end

    let(:expected_nodes_data) do
      {
        'Q9CAvRyRSBSBV3mxxbnPjQ' => { 'name' => '3be27c55fbd0bea8278c8e67f5e0dafa' },
        'ntd-0MYVRe-PnPSAH6jDDg' => { 'name' => '7aa07fa030f7e9ac302e7898fd400ded' },
        'MVSLeteKR_aiLjccChNYpA' => { 'name' => '443b4912dfc7c104afa8074e62246c22' },
        'uUZyFyxuThaHzsjmFRTxXw' => { 'name' => '30512cbcb29eeba7b854ef4f4663f42d' },
        'cNvDkFDWQ2miz5MvMmmVZg' => { 'name' => '9703b4532fa4f05e9fb305722bec0623' },
        '4Yk4GeazTE6gSId3OuOV1A' => { 'name' => 'ef6f30de3e7d26567960e0247026c2b8' }
      }
    end

    before do
      allow(transport_client).to receive(:nodes).and_return(nodes_client)
      allow(JayAPI::Elasticsearch::Stats::Nodes).to receive(:new).and_return(nodes)
    end

    it "requests the nodes' statistics from the Elasticsearch cluster" do
      expect(transport_client).to receive(:nodes)
      expect(nodes_client).to receive(:stats)
      method_call
    end

    context 'when the API request fails' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Forbidden,
          'You do not have permission to perform this action'
        ]
      end

      before do
        allow(nodes_client).to receive(:stats).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    it 'creates an instance of JayAPI::Elasticsearch::Stats::Nodes and passes the nodes data to it' do
      expect(JayAPI::Elasticsearch::Stats::Nodes)
        .to receive(:new).with(expected_nodes_data)

      method_call
    end

    it 'returns the instance of JayAPI::Elasticsearch::Stats::Nodes' do
      expect(method_call).to be(nodes)
    end
  end
end
