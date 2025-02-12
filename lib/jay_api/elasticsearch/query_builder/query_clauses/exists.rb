# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents an +Exists+ query
        # Documentation for this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-exists-query.html
        class Exists < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :field

          # @param [String, Symbol] field The name of the field.
          def initialize(field:)
            @field = field
          end

          # @return [Hash] The Hash representation of the Query Clause (in
          #   Elasticsearch's format)
          def to_h
            {
              exists: {
                field: field
              }
            }
          end
        end
      end
    end
  end
end
