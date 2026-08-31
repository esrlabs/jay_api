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
          attr_reader :size, :sort, :_source

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] size The number of hits that will be returned.
          # @param [Hash] sort How to sort the documents to determine the top
          #   hits. When not specified the documents are sorted by the score of
          #   the main query.
          # @param [FalseClass, String, Array<String>, Hash] _source Expression
          #   used for source filtering.
          # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-fields.html#source-filtering
          #   Elasticsearch's documentation for more information on what kind of
          #   expressions are allowed.
          # rubocop:disable-next Lint/UnderscorePrefixedVariableName -- to match Elasticsearch's name
          def initialize(name, size:, sort: nil, _source: nil)
            super(name)

            @size = size
            @sort = sort
            @_source = _source
          end

          # @return [self] A copy of the receiver.
          def clone
            optional_params = { sort: sort.deep_dup, _source: _source.deep_dup }.compact
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
                  sort: sort.deep_dup,
                  _source: _source.deep_dup
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
