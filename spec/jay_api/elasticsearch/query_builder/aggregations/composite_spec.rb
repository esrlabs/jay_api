# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/composite'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Composite do
  # rubocop:disable Lint/EmptyBlock (the code inside the block is not relevant for the tests)
  subject(:composite) { described_class.new(name, **constructor_params) {} }
  # rubocop:enable Lint/EmptyBlock

  let(:name) { 'products_by_brand' }
  let(:constructor_params) { {} }

  let(:sources) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources,
      to_a: 'Sources#to_a'
    )
  end

  before do
    allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources)
      .to receive(:new).and_return(sources)
  end

  describe '#initialize' do
    context 'when no block is given' do
      subject(:composite) { described_class.new(name, **constructor_params) }

      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError' do
        expect { composite }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
          'The Composite aggregation must be initialized with a block'
        )
      end
    end

    context 'when a block is given' do
      it 'creates a new instance of the Sources class and yields it to the block' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources).to receive(:new)
        expect { |block| described_class.new(name, **constructor_params, &block) }.to yield_with_args(sources)
      end
    end
  end

  describe '#clone' do
    subject(:method_call) { aggregation.clone }

    let(:aggregation) { composite }

    let(:sources_clone) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources,
        to_a: 'Sources#clone#to_a'
      )
    end

    before do
      allow(sources).to receive(:clone).and_return(sources_clone)
    end

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(aggregation)
    end

    it "returns an aggregation with the same 'name'" do
      expect(method_call.name).to be(name)
    end

    it 'calls #clone on the underlying Sources object' do
      expect(sources).to receive(:clone)
      method_call
    end

    it 'returns an aggregation with the cloned Source object' do
      expect(method_call.to_h).to eq('products_by_brand' => { composite: { sources: 'Sources#clone#to_a' } })
    end

    context "when no 'size' has been given to the constructor" do
      it "leaves the clone's 'size' as nil" do
        expect(method_call.size).to be_nil
      end
    end

    context "when a 'size' has been given to the constructor" do
      let(:size) { 10 }
      let(:constructor_params) { { size: size } }

      it "sets the clone's 'size' to the same value" do
        expect(method_call.size).to be(size)
      end
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms::#clone'
  end

  describe '#to_h' do
    subject(:method_call) { composite.to_h }

    context "when no 'size' has been given to the constructor" do
      let(:expected_hash) do
        {
          'products_by_brand' => { composite: { sources: 'Sources#to_a' } }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call.to_h).to eq(expected_hash)
      end
    end

    context "when 'size' has been given to the constructor" do
      let(:size) { 10 }
      let(:constructor_params) { { size: size } }

      let(:expected_hash) do
        {
          'products_by_brand' => { composite: { sources: 'Sources#to_a', size: 10 } }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call.to_h).to eq(expected_hash)
      end
    end
  end
end
