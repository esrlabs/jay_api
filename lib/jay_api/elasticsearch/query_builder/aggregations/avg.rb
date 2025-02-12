# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents an +avg+ aggregation in Elasticsearch.
        # Information on this type of aggregation can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-avg-aggregation.html
        class Avg < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :field, :missing

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field over which the average should be
          #   calculated.
          # @param [Float] missing The value to use for the documents where
          #   +field+ is missing. If no value is provided for +missing+ these
          #   documents are ignored,
          def initialize(name, field:, missing: nil)
            super(name)

            @field = field
            @missing = missing
          end

          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised. The Avg aggregation cannot have nested aggregations.
          def aggs
            no_nested_aggregations('Avg')
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(name, field: field, missing: missing)
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                avg: {
                  field: field,
                  missing: missing
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
