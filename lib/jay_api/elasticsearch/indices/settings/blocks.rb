# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    module Indices
      class Settings
        # Represents the block settings of an Elasticsearch index.
        class Blocks
          attr_reader :settings

          # @param [JayAPI::Elasticsearch::Indices::Settings] settings The
          #   parent +Settings+ object.
          def initialize(settings)
            @settings = settings
          end

          # @return [Boolean] True if the Index's write block has been set to
          #   true, false otherwise.
          def write_blocked?
            blocks_settings.fetch('write') == 'true'
          end

          # Sets the index's +write+ block to the given value. When the +write+
          # block is set to +true+ the index's data is read-only, but the
          # index's settings can still be changed. This allows maintenance tasks
          # to still be performed on the index.
          # @param [Boolean] value The new value for the +write+ block of the
          #   index.
          # @raise [Elasticsearch::Transport::Transport::Errors::ServerError] If
          #   an error occurs when trying to set the value of the block.
          def write=(value)
            unless [true, false].include?(value)
              raise ArgumentError, "Expected 'value' to be true or false, #{value.class} given"
            end

            return if write_blocked? == value

            settings.transport_client.indices.put_settings(
              index: settings.index_name,
              body: { 'blocks.write' => value }
            )
          end

          private

          # @return [Hash] The block settings of the index. Something like this:
          #
          #  { 'read_only_allow_delete' => 'false', 'write' => 'false' }
          #
          # @raise [KeyError] If the index's settings do not contain a "blocks"
          #   section.
          def blocks_settings
            settings.all.fetch('blocks')
          end
        end
      end
    end
  end
end
