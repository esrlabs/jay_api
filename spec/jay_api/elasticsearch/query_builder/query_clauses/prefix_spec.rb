# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/prefix'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Prefix do
  let(:prefix) do
    described_class.new(
      field: 'user.id',
      value: 'ki'
    )
  end

  describe '#to_h' do
    subject(:method_call) { prefix.to_h }

    let(:expected_hash) do
      {
        prefix: {
          'user.id' => {
            value: 'ki'
          }
        }
      }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
