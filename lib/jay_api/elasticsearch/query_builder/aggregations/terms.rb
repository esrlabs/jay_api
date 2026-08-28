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
          attr_reader :field, :script, :size, :order, :missing

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field whose unique values should be counted.
          # @param [JayAPI::Elasticsearch::Script] script If a script is given
          #   the aggregation will count the unique values returned by the
          #   script instead of the unique values in a specific field.
          # @param [Integer] size By default the aggregation returns the top 10
          #   unique values (the ones with the higher frequency). By specifying
          #   a size this can be changed.
          # @param [Hash] order A custom order for the buckets produced by the
          #   aggregation. By default, the +terms+ aggregation orders terms by
          #   descending document +_count+. This can be changed by providing a
          #   custom +order+ hash.
          # @param [String] missing The value to use for documents that are
          #   missing a value in the given +field+ or for whom the +script+
          #   returns +null+. When +missing+ is not given, such documents are
          #   ignored.
          # @raise [ArgumentError] If neither a +field+ nor a +script+ are given
          #   or if both of them are given. Only one should be present.
          # rubocop:disable Metrics/ParameterLists -- Constraint by Elasticsearch's design
          # :reek:LongParameterList -- Constraint by Elasticsearch's design
          def initialize(name, field: nil, script: nil, size: nil, order: nil, missing: nil)
            if (field.present? && script.present?) || (field.blank? && script.blank?)
              raise ArgumentError, "Either 'field' or 'script' must be provided"
            end

            super(name)

            @field = field
            @script = script
            @size = size
            @order = order
            @missing = missing
          end

          # rubocop:enable Metrics/ParameterLists

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(
              name, field: field, script: script, size: size, order: order&.deep_dup, missing: missing
            ).tap { |copy| copy.aggregations = aggregations.clone }
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
                  order: order,
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
