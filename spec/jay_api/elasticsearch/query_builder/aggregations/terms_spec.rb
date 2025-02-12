# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/terms'
require 'jay_api/elasticsearch/query_builder/script'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms do
  subject(:terms) { described_class.new(name, **constructor_params) }

  let(:name) { 'genres' }
  let(:field) { 'genre' }

  let(:script) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::Script,
      to_h: {
        source: <<~PAINLESS,
          String genre = doc['genre'].value;
          if (doc['product'].value.startsWith('Anthology')) {
            return genre + ' anthology';
          } else {
            return genre;
          }
        PAINLESS
        lang: 'painless'
      }
    )
  end

  let(:constructor_params) do
    { field: field }
  end

  shared_examples_for "#initialize when both 'field' and 'script' are absent" do
    it 'raises an ArgumentError' do
      expect { method_call }.to raise_error(
        ArgumentError,
        "Either 'field' or 'script' must be provided"
      )
    end
  end

  describe '#initialize' do
    subject(:method_call) { terms }

    context "when both 'field' and 'script' are absent" do
      subject(:method_call) { described_class.new(name) }

      it_behaves_like "#initialize when both 'field' and 'script' are absent"
    end

    context "when both 'field' and 'script' are nil" do
      subject(:method_call) { described_class.new(name, field: nil, script: nil) }

      it_behaves_like "#initialize when both 'field' and 'script' are absent"
    end

    context "when both 'field' and 'script' are given" do
      subject(:method_call) { described_class.new(name, field: field, script: script) }

      it_behaves_like "#initialize when both 'field' and 'script' are absent"
    end
  end

  describe '#aggs' do
    subject(:aggregation) { terms }

    context 'when no block is given' do
      it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#aggs with no block'
    end

    context 'when a block is given' do
      it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#aggs with a block'
    end
  end

  describe '#clone' do
    subject(:method_call) { aggregation.clone }

    let(:aggregation) { terms }

    let(:size) { 10 }

    let(:constructor_params) { { field: field, size: size } }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'is not the same object' do
      expect(method_call).not_to be(terms)
    end

    it 'has the same name' do
      expect(method_call.name).to be(terms.name)
    end

    it 'has the same field' do
      expect(method_call.field).to be(terms.field)
    end

    context "when no 'script' has been given" do
      it 'has the same script (nil)' do
        expect(method_call.script).to be(terms.script).and be_nil
      end
    end

    context "when a 'script' has been given" do
      let(:script) { instance_double(JayAPI::Elasticsearch::QueryBuilder::Script) }

      before do
        constructor_params.delete(:field)
        constructor_params[:script] = script
      end

      it 'has the same script' do
        expect(method_call.script).to be(terms.script).and be(script)
      end
    end

    it 'has the same size' do
      expect(method_call.size).to be(terms.size)
    end

    context "when no 'order' has been given" do
      it 'does not raise any errors' do
        expect { method_call }.not_to raise_error
      end
    end

    context "when a 'order' has been given" do
      let(:order) { { _key: :desc } }

      before { constructor_params[:order] = order }

      it 'has a copy of the order hash but not the same object' do
        expect(method_call.order).to eq(terms.order)
        expect(method_call.order).not_to be(terms.order)
      end
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms::#clone'
  end

  describe '#to_h' do
    subject(:method_call) { terms.to_h }

    let(:aggregation) { terms }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'
    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h with nesting allowed'

    context 'when a field is given' do
      let(:expected_hash) do
        {
          'genres' => {
            terms: { field: 'genre' }
          }
        }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when a script is given' do
      let(:constructor_params) do
        { script: script }
      end

      let(:expected_hash) do
        {
          'genres' => {
            terms: {
              script: {
                source: <<~PAINLESS,
                  String genre = doc['genre'].value;
                  if (doc['product'].value.startsWith('Anthology')) {
                    return genre + ' anthology';
                  } else {
                    return genre;
                  }
                PAINLESS
                lang: 'painless'
              }
            }
          }
        }
      end

      it "returns the expected hash (includes the Script's Hash)" do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when a 'size' is given" do
      let(:constructor_params) do
        { field: field, size: 100 }
      end

      let(:expected_hash) do
        {
          'genres' => {
            terms: { field: 'genre', size: 100 }
          }
        }
      end

      it 'returns the expected hash (includes the given size)' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when a custom order is given' do
      let(:constructor_params) do
        { field: field, order: { _key: :asc } }
      end

      let(:expected_hash) do
        {
          'genres' => {
            terms: { field: 'genre', order: { _key: :asc } }
          }
        }
      end

      it 'returns the expected hash (including the given order hash)' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
