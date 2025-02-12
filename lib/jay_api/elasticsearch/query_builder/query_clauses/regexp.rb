# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a +Regexp+ query in Elasticsearch
        # More information about this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-regexp-query.html
        class Regexp < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :field, :value

          # @param [String, Symbol] field The field where the regexp query
          #   should be applied.
          # @param [String, Regexp] value Terms to be found in +field+
          def initialize(field:, value:)
            super()
            @field = field
            @value = value
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's format)
          def to_h
            {
              regexp: {
                field => {
                  value: value
                }
              }
            }
          end
        end
      end
    end
  end
end
