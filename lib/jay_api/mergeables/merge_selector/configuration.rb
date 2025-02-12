# frozen_string_literal: true

require_relative 'merger'
require_relative '../../configuration'

module JayAPI
  module Mergeables
    module MergeSelector
      # A child class of Configuration, that contains the functionality that
      # allows the Configuration objects 'merge' with each other.
      class Configuration < JayAPI::Configuration
        public_class_method :from_hash

        # @param [JayAPI::Configuration, Hash] other The element with which the
        #   'self' object will be 'merged'.
        # @return [JayAPI::Mergeables::MergeSelector::Configuration] The result of the 'merge' between 'self'
        #   and 'other'.
        def merge_select(other)
          self.class.from_hash(
            Merger.new(
              with_indifferent_access,
              other.with_indifferent_access
            ).to_h
          )
        end
      end
    end
  end
end
