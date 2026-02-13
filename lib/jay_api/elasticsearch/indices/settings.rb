# frozen_string_literal: true

require_relative 'settings/blocks'

module JayAPI
  module Elasticsearch
    module Indices
      # Represents the settings of an Elasticsearch Index.
      class Settings
        attr_reader :transport_client, :index_name

        # @param [Elasticsearch::Transport::Client] transport_client Elasticsearch's
        #   transport client.
        # @param [String] index_name The name of the index this class will be
        #   handling settings for.
        def initialize(transport_client, index_name)
          @transport_client = transport_client
          @index_name = index_name
        end

        # @return [Hash] A Hash with all the settings for the index. It looks
        #   like this:
        #
        #   {
        #     "number_of_shards" => "5",
        #     "blocks" => { "read_only_allow_delete" => "false", "write" => "false" },
        #     "provided_name" => "xyz01_tests",
        #     "creation_date" => "1588701800423",
        #     "number_of_replicas" => "1",
        #     "uuid" => "VFx2e5t0Qgi-1zc2PUkYEg",
        #     "version" => { "created" => "7010199", "upgraded" => "7100299"}
        #   }
        #
        # @raise [Elasticsearch::Transport::Transport::Errors::ServerError] If
        #   an error occurs when trying to get the index's settings.
        # @raise [KeyError] If any of the expected hierarchical elements in the
        #   response are missing.
        def all
          transport_client.indices.get_settings(index: index_name)
                          .fetch(index_name).fetch('settings').fetch('index')
        end

        # @return [JayAPI::Elasticsearch::Indices::Settings::Blocks] The blocks
        #   settings for the given index.
        def blocks
          @blocks ||= ::JayAPI::Elasticsearch::Indices::Settings::Blocks.new(self)
        end
      end
    end
  end
end
