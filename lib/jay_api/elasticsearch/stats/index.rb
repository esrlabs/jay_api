# frozen_string_literal: true

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
      end
    end
  end
end
