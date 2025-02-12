# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when executing a query in Elasticsearch results
      # in failures, i.e., when a query can technically be processed, but
      # encounters issues during execution; the query is completed but returns
      # partial or problematic results. It does not necessarily stop the entire
      # request from completing
      class QueryExecutionFailure < JayAPI::Errors::Error
      end
    end
  end
end
