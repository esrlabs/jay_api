# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a Wildcard query in Elasticsearch
        # Documentation for this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-wildcard-query.html
        class Wildcard < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_accessor :field, :value

          # @param [String, Symbol] field The name of the field to search
          # @param [String] value The wildcard pattern.
          def initialize(field:, value:)
            @field = field
            @value = value
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's format)
          def to_h
            {
              wildcard: {
                "#{field}": {
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
