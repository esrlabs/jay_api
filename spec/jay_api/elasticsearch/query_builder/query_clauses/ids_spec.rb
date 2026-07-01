# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/ids'

# rubocop:disable RSpec/SpecFilePathFormat -- Avoid the name i_d_s_spec.rb
RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::IDs do
  subject(:ids_clause) { described_class.new(ids: ids) }

  let(:ids) { %w[1 4 100] }

  describe '#to_h' do
    subject(:method_call) { ids_clause.to_h }

    let(:expected_hash) do
      {
        ids: {
          values: %w[1 4 100]
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
