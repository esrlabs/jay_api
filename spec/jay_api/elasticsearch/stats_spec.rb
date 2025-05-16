# frozen_string_literal: true

require 'elasticsearch/transport/transport/errors'
require 'jay_api/elasticsearch/stats'

RSpec.describe JayAPI::Elasticsearch::Stats do
  subject(:stats) { described_class.new(transport_client) }

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

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client,
      indices: indices_client
    )
  end

  describe '#indices' do
    subject(:method_call) { stats.indices }

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
end
