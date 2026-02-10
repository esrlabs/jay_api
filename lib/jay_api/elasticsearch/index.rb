# frozen_string_literal: true

require_relative 'indexable'
require_relative 'indices/settings'
require_relative 'errors/writable_index_error'

module JayAPI
  module Elasticsearch
    # Represents an Elasticsearch index. Allows data to be pushed to it one
    # record at a time or in batches of the specified size.
    class Index
      include ::JayAPI::Elasticsearch::Indexable

      # @param [JayAPI::Elasticsearch::Client] client The Elasticsearch Client object.
      # @param [String] index_name The name of the Elasticsearch index.
      # @param [Integer] batch_size The size of the batch. When this many items
      #   are pushed into the index they are flushed to the Elasticsearch
      #   instance.
      # @param [Logging::Logger, nil] logger The logger object to use, if
      #   none is given a new one will be created.
      def initialize(client:, index_name:, batch_size: 100, logger: nil)
        super(client: client, index_names: [index_name], batch_size: batch_size, logger: logger)
      end

      # @return [String] The name of the Elasticsearch index.
      def index_name
        @index_name ||= index_names.first
      end

      # Sends a record to the Elasticsearch instance right away.
      # @param [Hash] data The data to be sent.
      # @param [String, nil] type The type of the document. When set to +nil+
      #   the decision is left to Elasticsearch's API. Which will normally
      #   default to +_doc+.
      # @return [Hash] A Hash containing information about the created document.
      #   An example of such Hash is:
      #
      #  {
      #    "_index" => "xyz01_unit_test",
      #    "_type" => "nested",
      #    "_id" => "SVY1mJEBQ5CNFZM8Lodt",
      #    "_version" => 1,
      #    "result" => "created",
      #    "_shards" => { "total" => 2, "successful" => 1, "failed" => 0 },
      #    "_seq_no" => 0,
      #    "_primary_term" => 1
      #  }
      #
      # For information on the contents of this Hash please see:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html#docs-index-api-response-body
      def index(data, type: DEFAULT_DOC_TYPE)
        super.first
      end

      # @return [JayAPI::Elasticsearch::Indices::Settings] The settings for the
      #   index.
      def settings
        # DO NOT MEMOIZE! Leave it to the caller.
        ::JayAPI::Elasticsearch::Indices::Settings.new(client.transport_client, index_name)
      end

      # Starts a Forced Segment Merge process on the index.
      #
      # ⚠️ For big indexes this process can take a very long time, make sure to
      #    adjust the timeout when creating the client.
      # @param [Boolean] only_expunge_deletes Specifies whether the operation
      #   should only remove deleted documents.
      # @raise [JayAPI::Elasticsearch::Errors::WritableIndexError] If the index
      #   is writable (hasn't been set to read-only).
      # @return [Hash] A +Hash+ with the result of the index merging process,
      #   it looks like this:
      #
      #   { "_shards" => { "total" => 10, "successful" => 10, "failed" => 0 } }
      def force_merge(only_expunge_deletes: nil)
        unless settings.blocks.write_blocked?
          raise ::JayAPI::Elasticsearch::Errors::WritableIndexError,
                "Write block for '#{index_name}' has not been enabled. " \
                "Please enable the index's write block before performing a segment merge"
        end

        params = { index: index_name, only_expunge_deletes: }.compact
        client.transport_client.indices.forcemerge(**params)
      end

      def destroy
        client.transport_client.indices.delete(index: index_name)
      end

      def clone!(target:)
        client.transport_client.indices.clone(index: index_name, target:)
      end
    end
  end
end
