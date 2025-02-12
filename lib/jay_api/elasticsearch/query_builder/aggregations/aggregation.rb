# frozen_string_literal: true

require_relative 'errors/aggregations_error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Base class for all Elasticsearch aggregation types. For more
        # information on what types of aggregations are available see:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
        class Aggregation
          attr_reader :name

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          def initialize(name)
            @name = name
          end

          # Creates nested aggregations inside the receiver.
          # @yieldparam [JayAPI::Elasticsearch::QueryBuilder::Aggregations] The
          #   receiver's nested aggregations object.
          # @return [JayAPI::Elasticsearch::QueryBuilder::Aggregations, self] If
          #   no block is given then the nested aggregations are returned
          #   instead of yielded. If a block is given then the receiver is
          #   returned.
          def aggs(&block)
            aggregations = self.aggregations ||= ::JayAPI::Elasticsearch::QueryBuilder::Aggregations.new
            return aggregations unless block

            block.call(aggregations)
            self
          end

          # @raise [NotImplementedError] Is always raised. The child classes
          #   **must** override the method.
          def clone
            raise NotImplementedError, "Please implement #{__method__} in #{self.class}"
          end

          protected

          attr_accessor :aggregations

          private

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h(&block)
            { name => block.call.merge(aggregations.to_h) } # nil.to_h -> {} and Aggregations#to_h = {} when empty.
          end

          # @param [String] aggregation The name of the aggregation that cannot
          #   have nested aggregations
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised..
          def no_nested_aggregations(aggregation)
            raise ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
                  "The #{aggregation} aggregation cannot have nested aggregations."
          end
        end
      end
    end
  end
end
