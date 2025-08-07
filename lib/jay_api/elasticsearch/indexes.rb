# frozen_string_literal: true

require_relative 'indexable'

module JayAPI
  module Elasticsearch
    # Represents a group of Elasticsearch indexes. Allows the execution of
    # searches over all of the specified indexes or push data to all of them
    # at the same time.
    class Indexes
      include ::JayAPI::Elasticsearch::Indexable

      # @param [JayAPI::Elasticsearch::Client] client The Elasticsearch Client object.
      # @param [Array<String>] index_names The names of the Elasticsearch indexes.
      # @param [Integer] batch_size The size of the batch. When this many items
      #   are pushed into the indexes they are flushed to the Elasticsearch
      #   instance.
      # @param [Logging::Logger, nil] logger The logger object to use, if
      #   none is given a new one will be created.
      def initialize(client:, index_names:, batch_size: 100, logger: nil)
        super

        return if (batch_size % index_names.size).zero?

        self.logger.warn(
          "'batch_size' is not a multiple of the number of elements in 'index_names'. " \
          "This can lead to a _bulk size slightly bigger than 'batch_size'"
        )
      end

      attr_reader :index_names
    end
  end
end
