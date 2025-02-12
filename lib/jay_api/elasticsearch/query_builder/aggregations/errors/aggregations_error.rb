# frozen_string_literal: true

require_relative '../../../../errors/error'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        module Errors
          # An error to be raised when aggregations are used or nested in an
          # unsupported way.
          class AggregationsError < ::JayAPI::Errors::Error; end
        end
      end
    end
  end
end
