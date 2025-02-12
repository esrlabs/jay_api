# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/wildcard'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard do
  subject(:wildcard) { described_class.new(field: field, value: value) }

  let(:field) { 'city' }
  let(:value) { '* City' } # ex. "New York City", "Mexico City", "Oklahoma City", etc

  describe '#to_h' do
    subject(:method_call) { wildcard.to_h }

    let(:expected_hash) do
      {
        wildcard: {
          city: {
            value: '* City'
          }
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
