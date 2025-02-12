# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'

module JayAPI
  module Elasticsearch
    # Manages and tracks the current batch within the QueryResults context. This class is responsible for
    # keeping track of the current batch start position and calculating the start position for the next batch
    # based on the batch size.
    class BatchCounter
      # The start of the batch to default to, if no other information is provided.
      DEFAULT_START = 0

      # @!attribute [r] batch_size
      #   @return [Integer] The size of each batch as determined by the query or the default size
      # @!attribute [r] start_current
      #   @return [Integer] The starting index of the current batch
      # @!attribute [r] start_next
      #   @return [Integer] The calculated starting index of the next batch
      attr_reader :batch_size, :start_current, :start_next

      # Creates a new +BatchCounter+ object by either updating a copy of the *batch* instance with new values or
      # creates a new instance if none exists.
      # @param [BatchCounter, nil] batch An existing BatchCounter to update or nil to create a new one
      # @param [Hash] query The Elasticsearch query containing the batch information
      # @param [Integer] size The size of the current batch; also serves as a default batch size
      # @return [BatchCounter] A new +BatchCounter+ created out of the given parameters.
      def self.create_or_update(batch, query, size)
        if batch
          new(query, size, batch.start_next, batch.start_next + size, batch.batch_size)
        else
          new(query, size)
        end
      end

      private

      attr_reader :query, :size

      # @param [Hash] query The Elasticsearch query which may contain :size and :from parameters
      # @param [Integer] size The size of the batch; used as a default when no batch_size is provided
      # @param [Integer, nil] start_current The starting index for the current batch; defaults to the query's :from
      #   or DEFAULT_START
      # @param [Integer, nil] start_next The starting index for the next batch; calculated from start_current and size
      # @param [Integer, nil] batch_size The size of the batch; taken from the query's :size or the provided size
      #   parameter
      def initialize(query, size, start_current = nil, start_next = nil, batch_size = nil)
        @query         = query.symbolize_keys
        @size          = size

        @start_current = start_current || fallback_start_current
        @start_next    = start_next    || fallback_start_next
        @batch_size    = batch_size    || fallback_batch_size
      end

      # Provides a default starting index for the next batch based on the current start index and batch size.
      # @return [Integer] The calculated start index for the next batch
      def fallback_start_next
        start_current + size
      end

      # Provides a default starting index for the current batch from the query or a constant.
      # @return [Integer] The starting index for the current batch
      def fallback_start_current
        query[:from] || DEFAULT_START
      end

      # Determines the batch size from the query or uses the provided size as a fallback.
      # @return [Integer] The size of the batch
      def fallback_batch_size
        query[:size] || size
      end
    end
  end
end
