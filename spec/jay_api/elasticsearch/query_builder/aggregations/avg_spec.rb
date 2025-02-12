# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/avg'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg do
  subject(:avg) { described_class.new(name, **constructor_params) }

  let(:name) { 'avg_grade' }
  let(:field) { 'grade' }

  let(:constructor_params) do
    { field: field }
  end

  describe '#aggs' do
    subject(:method_call) { avg.aggs }

    let(:expected_message) { 'The Avg aggregation cannot have nested aggregations.' }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations'
  end

  describe '#clone' do
    subject(:method_call) { avg.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(avg)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(avg.name)
    end

    it "has the same 'field'" do
      expect(method_call.field).to be(avg.field)
    end

    it "has the same 'missing'" do
      expect(method_call.missing).to be(avg.missing)
    end
  end

  describe '#to_h' do
    subject(:method_call) { aggregation.to_h }

    let(:aggregation) { avg }

    let(:expected_hash) do
      {
        'avg_grade' => {
          avg: { field: 'grade' }
        }
      }
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end

    context 'when `missing` is not given to the constructor' do
      it 'does not include a `missing` key' do
        expect(method_call).not_to have_key(:missing)
      end
    end

    context 'when `missing` is given as `nil` to the constructor' do
      let(:constructor_params) { { field: field, missing: nil } }

      it 'does not include a `missing` key' do
        expect(method_call).not_to have_key(:missing)
      end
    end

    context 'when `missing` is given to the the constructor' do
      let(:constructor_params) { { field: field, missing: 10 } }

      let(:expected_hash) do
        {
          'avg_grade' => {
            avg: { field: 'grade', missing: 10 }
          }
        }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
