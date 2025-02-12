# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/term'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Term do
  subject(:term) { described_class.new(field: field, value: value) }

  let(:field) { 'user.id' }
  let(:value) { 'kimchy' }

  describe '#to_h' do
    subject(:method_call) { term.to_h }

    let(:expected_hash) do
      {
        term: {
          'user.id' => {
            value: 'kimchy'
          }
        }
      }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
