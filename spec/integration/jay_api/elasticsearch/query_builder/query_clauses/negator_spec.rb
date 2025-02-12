# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/negator'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator do
  subject(:negator) { described_class.new(query_clause) }

  describe '#negate' do
    subject(:method_call) { negator.negate }

    context "when the 'query_clause' is a MatchAll clause" do
      let(:query_clause) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll.new }

      it 'returns a MatchNone clause' do
        expect(method_call).to be_a(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone)
      end
    end

    context "when the 'query_clause' is a MatchNone clause" do
      let(:query_clause) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone.new }

      it 'returns a MatchAll clause' do
        expect(method_call).to be_a(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll)
      end
    end

    context "when the 'query_clause' is any other clause" do
      let(:query_clause) do
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase.new(field: 'message', phrase: 'this is a test')
      end

      let(:expected_hash) do
        {
          bool: {
            must_not: [
              { match_phrase: { 'message' => 'this is a test' } }
            ]
          }
        }
      end

      it 'returns a Bool clause' do
        expect(method_call).to be_a(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
      end

      it 'returns a Bool clause with the expected hash representation' do
        expect(method_call.to_h).to eq(expected_hash)
      end
    end
  end
end
