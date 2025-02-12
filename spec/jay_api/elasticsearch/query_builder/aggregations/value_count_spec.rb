# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/value_count'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount do
  subject(:value_count) { described_class.new(name, **constructor_params) }

  let(:name) { 'types_count' }
  let(:field) { 'type' }

  let(:constructor_params) do
    { field: field }
  end

  describe '#aggs' do
    subject(:method_call) { value_count.aggs }

    let(:expected_message) { 'The Value Count aggregation cannot have nested aggregations.' }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations'
  end

  describe '#clone' do
    subject(:method_call) { value_count.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(value_count)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(value_count.name)
    end

    it "has the same 'field'" do
      expect(method_call.field).to be(value_count.field)
    end
  end

  describe '#to_h' do
    subject(:method_call) { aggregation.to_h }

    let(:aggregation) { value_count }

    let(:expected_hash) do
      {
        'types_count' => {
          value_count: { field: 'type' }
        }
      }
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
