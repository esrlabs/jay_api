# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/top_hits'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits do
  subject(:top_hits) { described_class.new(name, **constructor_params) }

  let(:name) { 'an_aggregation_sample' }

  let(:constructor_params) do
    { size: 1 }
  end

  describe '#clone' do
    subject(:method_call) { top_hits.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(top_hits)
    end

    it "has the same 'size'" do
      expect(method_call.size).to be(top_hits.size)
    end
  end

  describe '#to_h' do
    subject(:method_call) { top_hits.to_h }

    let(:expected_hash) do
      {
        'an_aggregation_sample' => {
          top_hits: { size: 1 }
        }
      }
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
