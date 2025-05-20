# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class Stats
      class Node
        # Holds storage information related to one of the nodes in the
        # Elasticsearch cluster.
        class Storage
          TOTAL_KEY = 'total_in_bytes'
          FREE_KEY = 'free_in_bytes'
          AVAILABLE_KEY = 'available_in_bytes'

          # @param [Hash] data Data about the Node's storage.
          def initialize(data)
            @data = data
          end

          # @return [Integer] The total size of the storage (in bytes)
          def total
            @total ||= data[TOTAL_KEY]
          end

          # @return [Integer] The total number of bytes that are free on the
          #   node.
          def free
            @free ||= data[FREE_KEY]
          end

          # @return [Integer] The total number of bytes that are available on
          #   the node. In general this is equal to #free, but not always.
          def available
            @available ||= data[AVAILABLE_KEY]
          end

          # @return [self] A new instance of the class with the added storage of
          #   the receiver and +other+.
          def +(other)
            raise ArgumentError, "Cannot add #{self.class} and #{other.class} together" unless other.is_a?(self.class)

            self.class.new(
              TOTAL_KEY => total + other.total,
              FREE_KEY => free + other.free,
              AVAILABLE_KEY => available + other.available
            )
          end

          private

          attr_reader :data
        end
      end
    end
  end
end
