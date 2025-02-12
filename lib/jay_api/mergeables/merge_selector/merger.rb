# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'

module JayAPI
  module Mergeables
    module MergeSelector
      # This class is responsible for merging two hashes together into a new one.
      # The merge behaviour here differs from the standard Hash merging, and can be
      # summarized with the following rules:
      # (Let A be a 'mergee' Hash and B a 'merger' Hash. This would be equivalent to
      # A.merge(B))
      # * All nodes in Hash B will completely overwrite nodes in Hash A.
      # * All nodes in Hash A that are not found in Hash B will be ignored in the result.
      # * If a node value is 'nil' in Hash B and the node matches a node in Hash A then
      #   the matching node in Hash A will be 'selected' to be in the result.
      # @see documentation/unit tests for details and examples.
      class Merger
        attr_reader :mergee, :merger

        # @param [HashWithIndifferentAccess] merger
        # @param [HashWithIndifferentAccess] mergee
        def initialize(mergee, merger)
          @merger = merger
          @mergee = mergee
        end

        # @return [HashWithIndifferentAccess] The merged result.
        def to_h
          {}.with_indifferent_access.tap { |hash| deep_merge(merger, hash) }
        end

        private

        # Recursively merges 'merger' and 'mergee' into the 'new_hash'.
        # @param [HashWithIndifferentAccess] merger The Hash 'B' in class documentation.
        # @param [HashWithIndifferentAccess] new_hash The placeholder Hash that is being
        #   constructed and will be eventually returned as part of the merge result.
        # @param [Array<String>] path A succession of keys leading to some value of the
        #   mergee hash (to be used in #dig).
        # This method smells like :reek:FeatureEnvy
        def deep_merge(merger, new_hash, *path)
          merger.each do |key, value|
            case value
            when NilClass
              new_hash[key] = mergee.dig(*path, key)
            when Hash
              deep_merge(value, new_hash[key] = {}.with_indifferent_access, *path, key)
            else
              new_hash[key] = value
            end
          end
        end
      end
    end
  end
end
