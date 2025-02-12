# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/filter'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter do
  # rubocop:disable Lint/EmptyBlock (the code inside the block is not relevant for the tests)
  subject(:filter) { described_class.new(name) {} }
  # rubocop:enable Lint/EmptyBlock

  let(:name) { 't_shirts' }

  let(:query_clauses) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::QueryClauses,
      to_h: 'QueryClauses#to_h'
    )
  end

  before do
    allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses)
      .to receive(:new).and_return(query_clauses)
  end

  describe '#initialize' do
    context 'when no block is given' do
      subject(:filter) { described_class.new(name) }

      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError' do
        expect { filter }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
          'The Filter aggregation must be initialized with a block'
        )
      end
    end

    context 'when a block is given' do
      it 'creates a new instance of the QueryClauses class' do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses).to receive(:new)
        expect { |block| described_class.new(name, &block) }.to yield_control
      end

      it 'yields the QueryClauses object to the given block' do
        expect { |block| described_class.new(name, &block) }.to yield_with_args(query_clauses)
      end
    end
  end

  describe '#clone' do
    subject(:method_call) { aggregation.clone }

    let(:aggregation) { filter }

    let(:query_clauses_clone) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses,
        to_h: 'QueryClauses#clone#to_h'
      )
    end

    before do
      allow(query_clauses).to receive(:clone).and_return(query_clauses_clone)
    end

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(filter)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(filter.name)
    end

    it 'calls #clone on the underlying QueryClauses object' do
      expect(query_clauses).to receive(:clone)
      method_call
    end

    it 'gets the cloned QueryClauses' do
      expect(method_call.to_h).to eq('t_shirts' => { filter: 'QueryClauses#clone#to_h' })
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms::#clone'
  end

  describe '#to_h' do
    subject(:method_call) { filter.to_h }

    let(:expected_hash) do
      {
        't_shirts' => { filter: 'QueryClauses#to_h' }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call.to_h).to eq(expected_hash)
    end
  end
end
