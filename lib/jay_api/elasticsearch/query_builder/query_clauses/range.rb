# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a +Range+ query in Elasticsearch
        # More information about this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html
        class Range < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          VALID_PARAMS = %i[gt gte lt lte].freeze

          attr_reader :field, :params

          # @param [Hash] params A hash with parameters for the class.
          # @option params [String, Symbol] :field The field where the range
          #   query should be applied.
          # @option params [String, Numeric] :gt Greater than
          # @option params [String, Numeric] :gte Greater than or equal
          # @option params [String, Numeric] :lt Less than
          # @option params [String, Numeric] :lte Less than or equal
          def initialize(params)
            @field = params.delete(:field) || raise(ArgumentError, "Missing required key 'field'")

            invalid_keys = params.keys - VALID_PARAMS
            raise ArgumentError, "Invalid keys: #{invalid_keys.join(', ')}" if invalid_keys.any?

            params = params.compact
            raise ArgumentError, "At least one of #{VALID_PARAMS.join(', ')} should be given" unless params.any?

            @params = params
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's format)
          def to_h
            {
              range: {
                field => params
              }
            }
          end
        end
      end
    end
  end
end
