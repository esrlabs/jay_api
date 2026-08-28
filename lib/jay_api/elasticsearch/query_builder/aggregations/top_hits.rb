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
        # https://www.elastic.co/docs/reference/aggregations/search-aggregations-metrics-top-hits-aggregation
        class TopHits < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :size, :sort

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] size The number of hits that will be returned.
          # @param [Hash] sort How to sort the documents to determine the top
          #   hits. When not specified the documents are sorted by the score of
          #   the main query.
          def initialize(name, size:, sort: nil)
            super(name)

            @size = size
            @sort = sort
          end

          # @return [self] A copy of the receiver.
          def clone
            optional_params = { sort: sort.deep_dup }.compact
            copy = self.class.new(name, size: size, **optional_params)
            copy.aggregations = aggregations.clone
            copy
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                top_hits: {
                  size: size,
                  sort: sort.deep_dup
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
