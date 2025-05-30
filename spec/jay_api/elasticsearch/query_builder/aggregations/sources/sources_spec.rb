# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/sources/sources'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources do
  subject(:sources) { described_class.new }

  let(:terms) do
    [
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms,
        to_h: { 'product' => { field: 'product.name' } }
      ),
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms,
        to_h: { 'brand' => { field: 'brand.name' } }
      )
    ]
  end

  before do
    allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms)
      .to receive(:new).and_return(*terms)
  end

  describe '#terms' do
    subject(:method_call) { sources.terms('product', field: 'product.name') }

    it 'creates an instance of the Terms source passing down the given parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms)
        .to receive(:new).with('product', field: 'product.name')

      method_call
    end

    it 'adds the Terms instance to the sources collection' do
      expect { method_call }.to change(sources, :to_a).from([]).to(['product' => { field: 'product.name' }])
    end
  end

  shared_context 'with elements in the sources collection' do
    before do
      sources.terms('product', field: 'product.name')
      sources.terms('brand', field: 'brand.name')
    end
  end

  describe '#to_a' do
    subject(:method_call) { sources.to_a }

    context 'when no sources have been added to the collection' do
      it 'returns an empty array' do
        expect(method_call).to be_an(Array).and be_empty
      end
    end

    context 'when some sources have been added to the collection' do
      let(:expected_array) do
        [
          { 'product' => { field: 'product.name' } },
          { 'brand' => { field: 'brand.name' } }
        ]
      end

      include_context 'with elements in the sources collection'

      it 'returns the expected array' do
        expect(method_call).to eq(expected_array)
      end
    end
  end

  shared_examples_for '#clone' do
    it 'returns a new instance of the class' do
      expect(method_call).to be_a(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(sources)
    end
  end

  describe '#clone' do
    subject(:method_call) { sources.clone }

    context 'when there are no elements in the collection' do
      it_behaves_like '#clone'

      it 'returns a collection which is also empty' do
        expect(method_call.to_a).to eq([])
      end
    end

    context 'when there are elements in the collection' do
      include_context 'with elements in the sources collection'

      it 'clones each of the sources' do
        expect(terms).to all(receive(:clone))
        method_call
      end

      it 'returns an equivalent collection' do
        expect(method_call.to_a).to eq(sources.to_a)
      end
    end
  end
end
