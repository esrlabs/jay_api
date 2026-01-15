# frozen_string_literal: true

require_relative 'aggregation'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +bucket_selector+ pipeline aggregation in Elasticsearch.
        # Docs:
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-pipeline-bucket-selector-aggregation.html
        class BucketSelector < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :buckets_path, :script, :gap_policy

          # @param [String] name The name used by Elasticsearch to identify the
          #   aggregation.
          # @param [Hash] buckets_path Path(s) to the metric or metrics
          #   over which the bucket_selector aggregation's script will operate.
          #   The keys are the names of the script variables, the values the
          #   paths to the metrics (relative to the parent aggregation).
          #   The script will receive these variables in its +params+.
          # @param [JayAPI::Elasticsearch::QueryBuilder::Script] script
          #   Script used to decide whether to keep each bucket.
          # @param [String, nil] gap_policy Optional gap policy (e.g. "skip",
          #   "insert_zeros").
          def initialize(name, buckets_path:, script:, gap_policy: nil)
            super(name)

            @buckets_path = buckets_path
            @script       = script
            @gap_policy   = gap_policy
          end

          # Bucket selector is a pipeline agg and cannot have nested aggregations.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError]
          def aggs
            no_nested_aggregations('Bucket Selector')
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(
              name,
              buckets_path: buckets_path.is_a?(Hash) ? buckets_path.dup : buckets_path,
              script:, # Script is immutable-ish, ok to reuse
              gap_policy:
            )
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h
            super do
              {
                bucket_selector: {
                  buckets_path: buckets_path,
                  script: script.to_h,
                  gap_policy: gap_policy
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
