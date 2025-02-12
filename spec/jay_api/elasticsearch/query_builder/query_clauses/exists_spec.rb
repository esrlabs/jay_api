# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/exists'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists do
  subject(:exists) { described_class.new(field: field) }

  let(:field) { 'user' }

  describe '#to_h' do
    subject(:method_call) { exists.to_h }

    let(:expected_hash) do
      {
        exists: {
          field: 'user'
        }
      }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
