# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string/inflections'

require_relative '../query_clauses'
require_relative 'aggregation'
require_relative 'errors/aggregations_error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +filter+ aggregation in Elasticsearch.
        # Information on this type of aggregation can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-filter-aggregation.html
        class Filter < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @yieldparam [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] The
          #   subquery for the +filter+ aggregation.
          def initialize(name, &block)
            super(name)

            unless block
              raise(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
                    "The #{self.class.name.demodulize} aggregation must be initialized with a block")
            end

            block.call(query)
          end

          # @return [self] A copy of the receiver.
          def clone
            # rubocop:disable Lint/EmptyBlock (The query will be assigned later)
            copy = self.class.new(name) {}
            # rubocop:enable Lint/EmptyBlock

            copy.query = query.clone
            copy.aggregations = aggregations.clone
            copy
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                filter: query.to_h
              }
            end
          end

          protected

          attr_writer :query

          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] The
          #   +filter+ aggregation's subquery.
          def query
            @query ||= ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses.new
          end
        end
      end
    end
  end
end
