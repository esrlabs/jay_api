# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a +Prefix+ query in Elasticsearch
        # More information about this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-prefix-query.html
        class Prefix < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :field, :value

          # @param [String, Symbol] field The field where the prefix query
          #   should be applied.
          # @param [String] value The prefix to be found in +field+
          def initialize(field:, value:)
            super()
            @field = field
            @value = value
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's format)
          def to_h
            {
              prefix: {
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
