# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/max'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Max do
  subject(:max) { described_class.new(name, **constructor_params) }

  let(:name) { 'max_price' }
  let(:field) { 'price' }

  let(:constructor_params) do
    { field: field }
  end

  describe '#aggs' do
    subject(:method_call) { max.aggs }

    let(:expected_message) { 'The Max aggregation cannot have nested aggregations.' }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations'
  end

  describe '#clone' do
    subject(:method_call) { max.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(max)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(max.name)
    end

    it "has the same 'field'" do
      expect(method_call.field).to be(max.field)
    end
  end

  describe '#to_h' do
    subject(:method_call) { aggregation.to_h }

    let(:aggregation) { max }

    let(:expected_hash) do
      {
        'max_price' => {
          max: { field: 'price' }
        }
      }
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
