# frozen_string_literal: true

require_relative 'index/totals'

module JayAPI
  module Elasticsearch
    class Stats
      # Holds information about an Elasticsearch Index.
      class Index
        attr_reader :name

        # @param [String] name The name of the index.
        # @param [Hash] data Information about the index.
        def initialize(name, data)
          @name = name
          @data = data
        end

        # @return [JayAPI::Elasticsearch::Stats::Index::Totals] Information
        #   about the index's total metrics.
        # @raise [KeyError] If the given data doesn't have a +total+ key.
        def totals
          @totals ||= ::JayAPI::Elasticsearch::Stats::Index::Totals.new(data.fetch('total'))
        end

        private

        attr_reader :data
      end
    end
  end
end
