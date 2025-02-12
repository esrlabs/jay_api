# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder'
require 'jay_api/elasticsearch/query_builder/aggregations/filter'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter do
  subject(:filter) do
    described_class.new('t_shirts') do |query|
      query.term(field: 'type', value: 't-shirt')
    end
  end

  describe '#to_h' do
    subject(:method_call) { filter.to_h }

    let(:expected_hash) do
      {
        't_shirts' => {
          filter: { term: { 'type' => { value: 't-shirt' } } }
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end

    context 'with nested aggregations' do
      before do
        filter.aggs do |aggs|
          aggs.avg('avg_price', field: 'price')
        end
      end

      let(:expected_hash) do
        {
          't_shirts' => {
            filter: { term: { 'type' => { value: 't-shirt' } } },
            aggs: {
              'avg_price' => { avg: { field: 'price' } }
            }
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
