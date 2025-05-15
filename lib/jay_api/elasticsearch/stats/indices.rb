# frozen_string_literal: true

require_relative 'index'

module JayAPI
  module Elasticsearch
    class Stats
      # Provides access to the list of indices returned by Elasticsearch's
      # Stats API
      class Indices
        # A lambda used to select / reject system indices (indices whose name
        # starts with dot).
        SYSTEM_SELECTOR = ->(name, _data) { name.starts_with?('.') }

        # @param [Hash{String=>Hash}] indices A +Hash+ with the information
        #   about the indices. Its keys are the names of the indices, its values
        #   hashes with information about each of the indices.
        def initialize(indices)
          @indices = indices
        end

        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Index>] A lazy
        #   enumerator of +Index+ objects, one for each of the indexes. All
        #   indices (system and user-defined are included).
        def all
          @all ||= with_lazy_instantiation { indices }
        end

        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Index>] A lazy
        #   enumerator of +Index+ objects. Includes only the system indices.
        def system
          @system ||= with_lazy_instantiation { indices.select(&SYSTEM_SELECTOR) }
        end

        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Index>] A lazy
        #   enumerator of +Index+ objects. Includes only the user-defined
        #   indices.
        def user
          @user ||= with_lazy_instantiation { indices.reject(&SYSTEM_SELECTOR) }
        end

        private

        attr_reader :indices

        # @param [Array(String, Hash)] args An array with two elements, the name
        #   of the index and its information.
        # @return [JayAPI::Elasticsearch::Stats::Index] An +Index+ object
        #   representing the given index.
        def build_index(args)
          JayAPI::Elasticsearch::Stats::Index.new(*args)
        end

        # Calls the given block and turns its return value into a lazy
        # enumerator that instantiates an +Index+ object for each of the
        # elements of the collection returned by block.
        # @return [Enumerator::Lazy<JayAPI::Elasticsearch::Stats::Index>]
        def with_lazy_instantiation(&block)
          block.call.lazy.map(&method(:build_index))
        end
      end
    end
  end
end
