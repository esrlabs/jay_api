# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when the ElasticSearch instance responds with
      # an error.
      class ElasticsearchError < JayAPI::Errors::Error; end
    end
  end
end
