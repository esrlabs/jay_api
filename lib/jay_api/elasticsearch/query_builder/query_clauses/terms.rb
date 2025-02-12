# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a Terms query in Elasticsearch.
        # Information about this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html
        class Terms < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :field, :terms

          # @param [String, Symbol] field The name of the field to search.
          # @param [Array<String>] terms The array of terms to search for.
          def initialize(field:, terms:)
            super()

            @field = field
            @terms = terms
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's DSL)
          def to_h
            {
              terms: {
                field => terms
              }
            }
          end
        end
      end
    end
  end
end
