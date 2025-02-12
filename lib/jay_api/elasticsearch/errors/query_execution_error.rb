# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when executing a query in Elasticsearch results
      # in errors, i.e, when a query cannot be executed; they typically indicate
      # fundamental problems with the request itself
      class QueryExecutionError < JayAPI::Errors::Error
      end
    end
  end
end
