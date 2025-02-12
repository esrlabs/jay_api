# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/match_none'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone do
  subject(:match_none) { described_class.new }

  describe '#to_h' do
    subject(:method_call) { match_none.to_h }

    it 'returns the expected hash' do
      expect(method_call).to eq(match_none: {})
    end
  end
end
