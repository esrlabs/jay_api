# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a +match_all+ query
        # Documentation for this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html
        class MatchAll < QueryClause
          # @return [Hash] The Hash representation of the Query Clause (in
          #   Elasticsearch's format)
          def to_h
            { match_all: {} }
          end
        end
      end
    end
  end
end
