# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +scripted_metric+ aggregation in Elasticsearch.
        # Information about this type of aggregation can be found in:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-scripted-metric-aggregation.html
        class ScriptedMetric < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :init_script, :map_script, :combine_script, :reduce_script

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] init_script The script that gets executed prior to
          #   any collection of documents. Allows the aggregation to set up any
          #   initial state.
          # @param [String] map_script The script that gets executed once per
          #   document collected. This is a required script.
          # @param [String] combine_script The script that gets executed once on
          #   each shard after document collection is complete. Allows the
          #   aggregation to consolidate the state returned from each shard.
          # @param [String] reduce_script The script that gets executed once on
          #   the coordinating node after all shards have returned their
          #   results. The script is provided with access to a variable +states+
          #   which is an array of the result of the combine_script on each
          #   shard.
          def initialize(name, map_script:, combine_script:, reduce_script:, init_script: nil)
            super(name)

            @init_script = init_script
            @map_script = map_script
            @combine_script = combine_script
            @reduce_script = reduce_script
          end

          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          #   Is always raised. The Scripted Metric aggregation cannot have
          #   nested aggregations.
          def aggs
            no_nested_aggregations('Scripted Metric')
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(
              name, map_script: map_script, combine_script: combine_script,
                    reduce_script: reduce_script, init_script: init_script
            )
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                scripted_metric: {
                  init_script: init_script,
                  map_script: map_script,
                  combine_script: combine_script,
                  reduce_script: reduce_script
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
