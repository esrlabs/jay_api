# frozen_string_literal: true

require_relative '../script'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      # Represents a scripted element in a query. This scripted element can be
      # used in different places. It can be used in a query clause, but can
      # also be used to create custom aggregations.
      # @deprecated Use +JayAPI::Elasticsearch::Script+ instead.
      Script = JayAPI::Elasticsearch::Script
    end
  end
end
