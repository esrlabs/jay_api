# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/array'

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a Query String query in Elasticsearch
        # Documentation for this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
        class QueryString < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :fields, :query

          # @param [String, Array<String>] fields The field or fields to search
          #   into.
          # @param [String] query The query string
          def initialize(query:, fields: nil)
            @fields = fields ? Array.wrap(fields) : nil
            @query = query
          end

          # @return [Hash] The Hash that represents this query (in
          #   Elasticsearch's format)
          def to_h
            {
              query_string: {
                query: query
              }.merge(fields_attribute)
            }
          end

          private

          # @return [Hash] A Hash with the +fields+ attribute for the
          #   +query_string+ clause or an empty array if no +fields+ were
          #   specified during initialization.
          def fields_attribute
            return {} unless fields

            { fields: fields }
          end
        end
      end
    end
  end
end
