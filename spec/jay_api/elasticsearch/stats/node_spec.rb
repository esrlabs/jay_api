# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/node'

RSpec.describe JayAPI::Elasticsearch::Stats::Node do
  subject(:node) { described_class.new(name, data) }

  let(:name) { 'Q9CAvRyRSBSBV3mxxbnPjQ' }
  let(:data) { {} }

  describe '#storage' do
    subject(:method_call) { node.storage }

    shared_examples_for '#storage when no storage-related data is available' do
      it 'raises a StatsDataNotAvailable error' do
        expect { method_call }.to raise_error(
          JayAPI::Elasticsearch::Stats::Errors::StatsDataNotAvailable,
          'Filesystem data not available for node Q9CAvRyRSBSBV3mxxbnPjQ'
        )
      end
    end

    context "when the node data doesn't include filesystem data" do
      let(:data) { {} }

      it_behaves_like '#storage when no storage-related data is available'
    end

    context 'when the node data includes filesystem data' do
      let(:fs_data) do
        {
          'data' => [{
            'type' => 'ext4',
            'total_in_bytes' => 316_863_741_952,
            'free_in_bytes' => 24_591_085_568,
            'available_in_bytes' => 24_574_308_352
          }]
        }
      end

      let(:data) do
        { 'fs' => fs_data }
      end

      context "when the node data doesn't include aggregated data about the filesystem" do
        it_behaves_like '#storage when no storage-related data is available'
      end

      context 'when the node data contains aggregated data about the filesystem' do
        let(:fs_data) do
          super().merge(
            'total' => {
              'total_in_bytes' => 316_863_741_952,
              'free_in_bytes' => 24_591_085_568,
              'available_in_bytes' => 24_574_308_352
            }
          )
        end

        let(:expected_storage_data) do
          {
            'total_in_bytes' => 316_863_741_952,
            'free_in_bytes' => 24_591_085_568,
            'available_in_bytes' => 24_574_308_352
          }
        end

        let(:storage) do
          instance_double(
            JayAPI::Elasticsearch::Stats::Node::Storage
          )
        end

        before do
          allow(JayAPI::Elasticsearch::Stats::Node::Storage)
            .to receive(:new).and_return(storage)
        end

        it 'initializes the Storage instance from the aggregated data' do
          expect(JayAPI::Elasticsearch::Stats::Node::Storage).to receive(:new)
            .with(expected_storage_data)

          method_call
        end

        it 'returns the Storage instance' do
          expect(method_call).to be(storage)
        end
      end
    end
  end
end
