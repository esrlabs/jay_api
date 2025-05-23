# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        module Sources
          # Represents a "Terms" value source for a Composite aggregation.
          # More information about this type of value source can be found here:
          # https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-composite-aggregation#_terms
          class Terms
            attr_reader :name, :field, :order, :missing_bucket, :missing_order

            # @param [String] name The name for the value source.
            # @param [String] field The field for the value source.
            # @param [String, nil] order The order in which the values coming
            #   from this data source should be ordered, this can be either
            #   "asc" or "desc"
            # @param [Boolean] missing_bucket Whether or not a bucket for the
            #   documents without a value in +field+ should be created.
            # @param [String] missing_order Where to put the bucket for the
            #   documents with a missing value, either "first" or "last".
            def initialize(name, field:, order: nil, missing_bucket: nil, missing_order: nil)
              @name = name
              @field = field
              @order = order
              @missing_bucket = missing_bucket
              @missing_order = missing_order
            end

            # @return [self] A copy of the receiver.
            def clone
              self.class.new(
                name, field: field, order: order, missing_bucket: missing_bucket, missing_order: missing_order
              )
            end

            # @return [Hash] The hash representation for the value source.
            def to_h
              {
                name => {
                  terms: {
                    field: field,
                    order: order,
                    missing_bucket: missing_bucket,
                    missing_order: missing_order
                  }.compact
                }
              }
            end
          end
        end
      end
    end
  end
end
