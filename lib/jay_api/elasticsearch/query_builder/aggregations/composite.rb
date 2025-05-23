# frozen_string_literal: true

require_relative 'aggregation'
require_relative 'sources/sources'
require_relative 'errors/aggregations_error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        class Composite < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :size

          def initialize(name, size: nil, &block)
            unless block
              raise(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
                    "The #{self.class.name.demodulize} aggregation must be initialized with a block")
            end

            super(name)
            @size = size
            block.call(sources)
          end

          def clone
            # rubocop:disable Lint/EmptyBlock (The sources will be assigned later)
            copy = self.class.new(name, size: size) {}
            # rubocop:enable Lint/EmptyBlock

            copy.aggregations = aggregations.clone
            copy.sources = sources.clone
            copy
          end

          def to_h
            super do
              {
                composite: {
                  sources: sources.to_h,
                  size: size
                }.compact
              }
            end
          end

          protected

          attr_writer :sources

          def sources
            @sources ||= ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Sources.new
          end
        end
      end
    end
  end
end
