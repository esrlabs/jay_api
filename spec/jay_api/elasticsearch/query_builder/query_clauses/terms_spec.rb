# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/terms'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms do
  subject(:terms_clause) { described_class.new(field: field, terms: terms) }

  let(:field) { 'user.id' }
  let(:terms) { %w[kimchy elkbee] }

  describe '#to_h' do
    subject(:method_call) { terms_clause.to_h }

    let(:expected_hash) do
      {
        terms: {
          'user.id' => %w[kimchy elkbee]
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
