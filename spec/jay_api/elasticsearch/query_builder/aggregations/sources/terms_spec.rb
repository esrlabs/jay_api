# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/sources/terms'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms do
  subject(:terms) { described_class.new(name, **constructor_params) }

  let(:name) { 'product' }
  let(:constructor_params) { { field: 'product.name' } }

  describe '#clone' do
    subject(:method_call) { terms.clone }

    it "returns an instance of #{described_class}" do
      expect(method_call).to be_a(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(terms)
    end

    it "has the same 'name'" do
      expect(method_call.name).to eq('product')
    end

    it "has the same 'field'" do
      expect(method_call.field).to eq('product.name')
    end

    context "when no 'order' has been given" do
      it 'has no order' do
        expect(method_call.order).to be_nil
      end
    end

    context 'when an order has been given' do
      let(:constructor_params) { super().merge(order: 'desc') }

      it 'has the same order' do
        expect(method_call.order).to eq('desc')
      end
    end

    context 'when no configuration for missing values has been given' do
      it 'has its "missing values" attributes set to nil' do
        expect(method_call.missing_bucket).to be_nil
        expect(method_call.missing_order).to be_nil
      end
    end

    context 'when missing values configuration has been given' do
      let(:constructor_params) { super().merge(missing_bucket: true, missing_order: 'first') }

      it 'has the sam values in its "missing values" attributes' do
        expect(method_call.missing_bucket).to be(true)
        expect(method_call.missing_order).to eq('first')
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { terms.to_h }

    let(:expected_hash) do
      { 'product' => { terms: { field: 'product.name' } } }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end

    context "when an 'order' has been given" do
      let(:constructor_params) { super().merge(order: 'asc') }

      let(:expected_hash) do
        { 'product' => { terms: { field: 'product.name', order: 'asc' } } }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when 'missing_bucket' has been set to true" do
      let(:constructor_params) { super().merge(missing_bucket: true) }

      let(:expected_hash) do
        { 'product' => { terms: { field: 'product.name', missing_bucket: true } } }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when 'missing_bucket' and 'missing_order' have been given" do
      let(:constructor_params) { super().merge(missing_bucket: true, missing_order: 'last') }

      let(:expected_hash) do
        { 'product' => { terms: { field: 'product.name', missing_bucket: true, missing_order: 'last' } } }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
