# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/nodes'

RSpec.describe JayAPI::Elasticsearch::Stats::Nodes do
  subject(:nodes) { described_class.new(nodes_hash) }

  let(:nodes_hash) do
    {
      'Q9CAvRyRSBSBV3mxxbnPjQ' => {
        'indices' => { 'docs_count' => 218_737_641 }
      },
      'ntd-0MYVRe-PnPSAH6jDDg' => {
        'indices' => { 'docs_count' => 197_437_505 }
      },
      'MVSLeteKR_aiLjccChNYpA' => {
        'indices' => { 'docs_count' => 0 }
      }
    }
  end

  describe '#size' do
    subject(:method_call) { nodes.size }

    it 'does not initialize any Node objets' do
      expect(JayAPI::Elasticsearch::Stats::Node).not_to receive(:new)
      method_call
    end

    it 'returns the number of nodes in the given hash' do
      expect(method_call).to eq(3)
    end
  end

  describe '#all' do
    subject(:method_call) { nodes.all }

    let(:expected_nodes) do
      %w[Q9CAvRyRSBSBV3mxxbnPjQ ntd-0MYVRe-PnPSAH6jDDg MVSLeteKR_aiLjccChNYpA]
    end

    it 'returns an Enumerator::Lazy' do
      expect(method_call).to be_a(Enumerator::Lazy)
    end

    it 'includes the expected number of nodes' do
      expect(method_call.size).to eq(3)
    end

    it 'includes only instances of JayAPI::Elasticsearch::Stats::Node' do
      expect(method_call).to all(be_a(JayAPI::Elasticsearch::Stats::Node))
    end

    it 'includes the expected list of indices' do
      # #to_a is needed here because of the lazy enumerator.
      expect(method_call.map(&:name).to_a).to eq(expected_nodes)
    end
  end
end
