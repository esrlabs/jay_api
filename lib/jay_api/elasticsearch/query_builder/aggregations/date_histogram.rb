# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        # Represents a +date_histogram+ aggregation in Elasticsearch.
        # Information about this type of aggregation can be found in:
        # https://www.elastic.co/docs/reference/aggregations/search-aggregations-bucket-datehistogram-aggregation
        class DateHistogram < ::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation
          attr_reader :field, :calendar_interval, :format

          # @param [String] name The name used by Elasticsearch to identify each
          #   of the aggregations.
          # @param [String] field The field over which the date histogram should
          #   be performed. This field **MUST** be a date or date range field.
          # @param [String] calendar_interval The interval that should be used
          #   for the histogram. For a list of accepted intervals check the
          #   aggregation's documentation. This **must** be a single calendar
          #   unit. I.e. +1d+ is accepted but +2d+ is not.
          # @param [String] format The format in which the date interval keys
          #   should be represented. For information on what this format can be
          #   check the aggregation's documentation.
          def initialize(name, field:, calendar_interval:, format: nil)
            @field = field
            @calendar_interval = calendar_interval
            @format = format
            super(name)
          end

          # @return [self] A copy of the receiver.
          def clone
            self.class.new(name, field: field, calendar_interval: calendar_interval, format: format).tap do |copy|
              copy.aggregations = aggregations.clone
            end
          end

          # @return [Hash] The Hash representation of the +Aggregation+.
          #   Properly formatted for Elasticsearch.
          def to_h(&block)
            super do
              {
                date_histogram: {
                  field: field,
                  calendar_interval: calendar_interval,
                  format: format
                }.compact
              }
            end
          end
        end
      end
    end
  end
end
