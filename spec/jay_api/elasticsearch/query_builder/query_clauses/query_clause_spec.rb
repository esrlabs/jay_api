# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/query_clause'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause do
  subject(:query_clause) { described_class.new }

  describe '#to_h' do
    subject(:method_call) { query_clause.to_h }

    it 'raises a NotImplementedError' do
      expect { method_call }.to raise_error(
        NotImplementedError,
        'Please implement the #to_h method in the JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause class'
      )
    end
  end
end
