# frozen_string_literal: true

require 'forwardable'

require_relative 'aggregations/aggregation'
require_relative 'aggregations/avg'
require_relative 'aggregations/filter'
require_relative 'aggregations/scripted_metric'
require_relative 'aggregations/sum'
require_relative 'aggregations/terms'
require_relative 'aggregations/value_count'
require_relative 'aggregations/top_hits'
require_relative 'aggregations/errors'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      # The list of aggregations to be included in an Elasticsearch query.
      class Aggregations
        extend Forwardable

        def_delegators :aggregations, :any?, :none?

        def initialize
          @aggregations = []
        end

        # Adds a +terms+ type aggregation. For information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms#initialize
        def terms(name, field: nil, script: nil, size: nil, order: nil)
          add(
            ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms.new(
              name, field: field, script: script, size: size, order: order
            )
          )
        end

        # Adds an +avg+ type aggregation. For information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg#initialize
        def avg(name, field:, missing: nil)
          add(
            ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg.new(
              name, field: field, missing: missing
            )
          )
        end

        # Adds a +sum+ type aggregation. For information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum#initialize
        def sum(name, field:, missing: nil)
          add(
            ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum.new(
              name, field: field, missing: missing
            )
          )
        end

        # Adds a +value_count+ type aggregation. For information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount#initialize
        def value_count(name, field:)
          add(
            ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount.new(
              name, field: field
            )
          )
        end

        # Adds a +top_hits+ type aggregation. For more information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits#initialize
        def top_hits(name, size:)
          add(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits.new(name, size: size))
        end

        # Adds an +scripted_metric+ type aggregation. For information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric#initialize
        def scripted_metric(name, map_script:, combine_script:, reduce_script:, init_script: nil)
          add(
            ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric.new(
              name, map_script: map_script, combine_script: combine_script,
                    reduce_script: reduce_script, init_script: init_script
            )
          )
        end

        # Adds a +filter+ type aggregation. For more information about the parameters
        # @see JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter#initialize
        def filter(name, &block)
          add(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter.new(name, &block))
        end

        # Returns a Hash with the correct format for the current list of
        # aggregations. For example:
        #
        #   {
        #     "aggs" => {
        #       "my-agg-name" => {
        #         "terms" => {
        #           "field" => "my_field"
        #         }
        #       },
        #       "my-average" => {
        #         "avg" => {
        #           "field" => "my_numeric_field"
        #         }
        #       }
        #     }
        #   }
        #
        # @return [Hash] A Hash with the list of aggregations
        def to_h
          return {} if none?

          {
            aggs: aggregations.inject({}) do |hash, aggregation|
              hash.merge(aggregation.to_h)
            end
          }
        end

        # @param [self] other The object to merge with the receiver.
        # @return [self] A new object, which represents the combination of the
        #   aggregations in the receiver and +other+.
        # @raise [TypeError] If +other+ is not an instance of the same class
        #   (or a subclass of it).
        def merge(other)
          klass = self.class
          raise TypeError, "Cannot merge #{klass} with #{other.class}" unless other.is_a?(klass)

          klass.new.tap do |merged|
            merged.aggregations = aggregations.map(&:clone) + other.aggregations.map(&:clone)
          end
        end

        # @return [self] A copy of the receiver.
        def clone
          self.class.new.tap do |clone|
            clone.aggregations = aggregations.map(&:clone)
          end
        end

        protected

        attr_accessor :aggregations

        # Adds the given +aggregation+ to the +aggregations+ array.
        # @return [JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation]
        #   The added aggregation. This has two reasons:
        #    * To keep the inner +aggregations+ array from leaking out.
        #    * To allow nesting of aggregations in the future.
        def add(aggregation)
          aggregations << aggregation
          aggregation
        end
      end
    end
  end
end
