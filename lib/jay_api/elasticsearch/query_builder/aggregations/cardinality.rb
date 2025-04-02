# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +cardinality+ aggregation in Elasticsearch.
        # Information on this type of aggregation can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
        class Cardinality < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :field

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field whose cardinality (number of unique
          #   values) should be calculated.
          def initialize(name, field:)
            super(name)

            @field = field
          end

          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised. The Cardinality aggregation cannot have nested
          #   aggregations.
          def aggs
            no_nested_aggregations('Cardinality')
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(name, field: field)
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                cardinality: {
                  field: field
                }
              }
            end
          end
        end
      end
    end
  end
end
