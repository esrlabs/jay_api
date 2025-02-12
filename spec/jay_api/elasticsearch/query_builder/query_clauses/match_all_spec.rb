# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/match_all'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll do
  subject(:match_all) { described_class.new }

  describe '#to_h' do
    subject(:method_call) { match_all.to_h }

    it 'returns the expected hash' do
      expect(method_call).to eq(match_all: {})
    end
  end
end
