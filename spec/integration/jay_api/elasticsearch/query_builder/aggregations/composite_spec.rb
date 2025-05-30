# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/composite'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Composite do
  subject(:composite) do
    described_class.new('products_by_brand', **constructor_params) do |sources|
      sources.terms('product', field: 'product.name', order: 'asc')
      sources.terms('brand', field: 'brand.name')
    end
  end

  let(:constructor_params) { {} }

  describe '#to_h' do
    subject(:method_call) { composite.to_h }

    let(:expected_hash) do
      {
        'products_by_brand' => {
          composite: {
            sources: [
              { 'product' => { terms: { field: 'product.name', order: 'asc' } } },
              { 'brand' => { terms: { field: 'brand.name' } } }
            ]
          }
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end

    context "when a 'size' has been specified" do
      let(:constructor_params) { { size: 10 } }

      let(:expected_hash) do
        {
          'products_by_brand' => {
            composite: {
              sources: [
                { 'product' => { terms: { field: 'product.name', order: 'asc' } } },
                { 'brand' => { terms: { field: 'brand.name' } } }
              ],
              size: 10
            }
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'with nested aggregations' do
      before do
        composite.aggs do |aggs|
          aggs.avg('avg_price', field: 'product.price')
        end
      end

      let(:expected_hash) do
        {
          'products_by_brand' => {
            composite: {
              sources: [
                { 'product' => { terms: { field: 'product.name', order: 'asc' } } },
                { 'brand' => { terms: { field: 'brand.name' } } }
              ]
            },
            aggs: {
              'avg_price' => { avg: { field: 'product.price' } }
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
