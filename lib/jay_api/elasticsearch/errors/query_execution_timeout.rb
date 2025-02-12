# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when executing a query in Elasticsearch times out.
      class QueryExecutionTimeout < JayAPI::Errors::Error
      end
    end
  end
end
