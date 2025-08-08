# frozen_string_literal: true

require_relative 'indexable'

module JayAPI
  module Elasticsearch
    # Represents an Elasticsearch index. Allows data to be pushed to it one
    # record at a time or in batches of the specified size.
    class Index
      include ::JayAPI::Elasticsearch::Indexable

      attr_reader :index_name
    end
  end
end
