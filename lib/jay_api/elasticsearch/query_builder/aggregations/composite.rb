# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string/inflections'

require_relative 'aggregation'
require_relative 'sources/sources'
require_relative 'errors/aggregations_error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a Composite aggregation in Elasticsearch. For more
        # information about this type of aggregation:
        # @see https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-composite-aggregation
        class Composite < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :size

          # @param [String] name The name of the composite aggregation.
          # @param [Integer] size The number of composite buckets to return.
          # @yieldparam [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources]
          #   The collection of sources for the composite aggregation. This
          #   should be used by the caller to add sources to the composite
          #   aggregation.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   If the method is called without a block.
          def initialize(name, size: nil, &block)
            unless block
              raise(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
                    "The #{self.class.name.demodulize} aggregation must be initialized with a block")
            end

            super(name)
            @size = size
            block.call(sources)
          end

          # @return [self] A copy of the receiver. Sources and nested
          #   aggregations are also cloned.
          def clone
            # rubocop:disable Lint/EmptyBlock (The sources will be assigned later)
            copy = self.class.new(name, size: size) {}
            # rubocop:enable Lint/EmptyBlock

            copy.aggregations = aggregations.clone
            copy.sources = sources.clone
            copy
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                composite: {
                  sources: sources.to_a,
                  size: size
                }.compact
              }
            end
          end

          protected

          attr_writer :sources # Used by the #clone method

          # @return [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources]
          #   The collection of sources of the composite aggregation.
          def sources
            @sources ||= ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources.new
          end
        end
      end
    end
  end
end
