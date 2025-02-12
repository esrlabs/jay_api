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
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-filter-aggregation.html
        class TopHits < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :size

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] size The number of hits that will be returned.
          def initialize(name, size:)
            super(name)

            @size = size
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(name, size: size)
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                top_hits: {
                  size: size
                }
              }
            end
          end
        end
      end
    end
  end
end
