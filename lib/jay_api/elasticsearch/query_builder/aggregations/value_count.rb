# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +value_count+ aggregation in Elasticsearch.
        # Information about this type of aggregation can be found in:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-valuecount-aggregation.html
        class ValueCount < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          # TODO: Add script support to the aggregation

          attr_reader :field

          # @param [String] field The whose non-empty values should be counted.
          def initialize(name, field:)
            @field = field
            super(name)
          end

          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised. The Value Count aggregation cannot have nested
          #   aggregations.
          def aggs
            no_nested_aggregations('Value Count')
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
                value_count: {
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
