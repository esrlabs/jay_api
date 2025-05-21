# frozen_string_literal: true

require 'forwardable'

require_relative 'node'

module JayAPI
  module Elasticsearch
    class Stats
      # Provides access to the list of nodes returned by Elasticsearch's Stats API
      class Nodes
        extend Forwardable

        def_delegator :nodes, :size

        # @param [Hash] nodes Information about the nodes in the Elasticsearch
        #   cluster.
        def initialize(nodes)
          @nodes = nodes
        end

        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Node>] A lazy
        #   enumerator of +Node+ objects, one for each of the nodes.
        def all
          @all ||= with_lazy_instantiation { nodes }
        end

        private

        attr_reader :nodes

        def build_node(args)
          ::JayAPI::Elasticsearch::Stats::Node.new(*args)
        end

        # Calls the given block and turns its return value into a lazy
        # enumerator that instantiates a +Node+ object for each of the
        # elements of the collection returned by the block.
        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Node>]
        def with_lazy_instantiation(&block)
          block.call.lazy.map(&method(:build_node))
        end
      end
    end
  end
end
