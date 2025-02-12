# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/deep_dup'

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +terms+ aggregation in Elasticsearch.
        # Information about this type of aggregation can be found in:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
        class Terms < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :field, :script, :size, :order

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field whose unique values should be counted.
          # @param [JayAPI::Elasticsearch::QueryBuilder::Script] script If a
          #   script is given the aggregation will count the unique values
          #   returned by the script instead of the unique values in a specific
          #   field.
          # @param [Integer] size By default the aggregation returns the top 10
          #   unique values (the ones with the higher frequency). By specifying
          #   a size this can be changed.
          # @param [Hash] order A custom order for the buckets produced by the
          #   aggregation. By default, the +terms+ aggregation orders terms by
          #   descending document +_count+. This can be changed by providing a
          #   custom +order+ hash.
          # @raise [ArgumentError] If neither a +field+ nor a +script+ are given
          #   or if both of them are given. Only one should be present.
          def initialize(name, field: nil, script: nil, size: nil, order: nil)
            if (field.present? && script.present?) || (field.blank? && script.blank?)
              raise ArgumentError, "Either 'field' or 'script' must be provided"
            end

            super(name)

            @field = field
            @script = script
            @size = size
            @order = order
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(name, field: field, script: script, size: size, order: order&.deep_dup).tap do |copy|
              copy.aggregations = aggregations.clone
            end
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                terms: {
                  field: field,
                  size: size,
                  script: script&.to_h,
                  order: order
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
