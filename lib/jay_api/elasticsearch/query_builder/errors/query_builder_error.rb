# frozen_string_literal: true

require_relative '../../../errors/error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      module Errors
        # An error to be raised when the user tries to build a query which would
        # result in an invalid query for Elasticsearch.
        class QueryBuilderError < JayAPI::Errors::Error
        end
      end
    end
  end
end
