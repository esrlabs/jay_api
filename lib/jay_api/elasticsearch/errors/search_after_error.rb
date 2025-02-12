# frozen_string_literal: true

require_relative 'elasticsearch_error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when an issue arises while using Elasticsearch's
      # 'search_after' parameter.
      class SearchAfterError < ElasticsearchError; end
    end
  end
end
