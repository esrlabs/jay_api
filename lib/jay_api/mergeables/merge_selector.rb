# frozen_string_literal: true

require_relative 'merge_selector/configuration'

module JayAPI
  # This class declaration serves as an extension of the already
  # defined JayAPI::Configuration class.
  class Configuration
    # @return [JayAPI::Mergeables::MergeSelector::Configuration] A Configuration object
    #   that contains the merging functionality.
    def with_merge_selector
      JayAPI::Mergeables::MergeSelector::Configuration.from_hash(deep_to_h)
    end
  end
end
