# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when an attempt is made to perform force_merge
      # over an index which hasn't been set to be read-only.
      class WritableIndexError < ::JayAPI::Errors::Error; end
    end
  end
end
