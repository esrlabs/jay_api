# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/match_phrase'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase do
  subject(:match_phrase) { described_class.new(field: field, phrase: phrase) }

  let(:field) { 'some.field' }
  let(:phrase) { 'A picture is worth 1000 words' }

  describe '#to_h' do
    subject(:method_call) { match_phrase.to_h }

    let(:expected_hash) do
      {
        match_phrase: {
          'some.field' => 'A picture is worth 1000 words'
        }
      }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
