# frozen_string_literal: true

require_relative 'bool'
require_relative 'match_all'
require_relative 'match_none'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # A class capable of negating any QueryClause object
        class Negator
          # A mapping between QueryClause classes and their corresponding inverse
          # clauses. Only some of the clauses can be directly inverted.
          INVERSE_CLAUSES = {
            ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll =>
              ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone,
            ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone =>
              ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll
          }.freeze

          attr_reader :query_clause

          # @param [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause] query_clause
          #   The +QueryClause+ to negate.
          def initialize(query_clause)
            @query_clause = query_clause
          end

          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause]
          #   The negated version of the given +QueryClause+
          def negate
            @negate ||= INVERSE_CLAUSES[query_clause.class]&.new ||
                        ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool.new.must_not do |bool_query|
                          bool_query << query_clause
                        end
          end
        end
      end
    end
  end
end
