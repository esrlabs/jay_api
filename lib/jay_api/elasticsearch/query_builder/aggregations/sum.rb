# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +sum+ aggregation in Elasticsearch.
        # Information on this type of aggregation can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-sum-aggregation.html
        class Sum < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          # TODO: Add script support to the aggregation

          attr_reader :field, :missing

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field whose values should be added-up
          # @param [Numeric] missing The value to use when the field doesn't
          #   have a value. The type of the parameter depends on the type of the
          #   field in Elasticsearch.
          def initialize(name, field:, missing: nil)
            super(name)

            @field = field
            @missing = missing
          end

          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised. The Sum aggregation cannot have nested aggregations.
          def aggs
            no_nested_aggregations('Sum')
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
                sum: {
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
