# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents an IDs query in Elasticsearch.
        # Information about this type of query can be found here:
        # https://www.elastic.co/docs/reference/query-languages/query-dsl/query-dsl-ids-query
        class IDs < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :ids

          # @param [Array<String>] ids The ids of the documents to match.
          def initialize(ids:)
            super()

            @ids = ids
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's DSL)
          def to_h
            {
              ids: {
                values: ids
              }
            }
          end
        end
      end
    end
  end
end
