# frozen_string_literal: true

require_relative 'errors/elasticsearch_error'
require_relative 'errors/end_of_query_results_error'
require_relative 'errors/query_execution_error'
require_relative 'errors/query_execution_failure'
require_relative 'errors/query_execution_timeout'
require_relative 'errors/search_after_error'
require_relative 'errors/writable_index_error'

module JayAPI
  module Elasticsearch
    # Namespace for all error classes related to Elasticsearch
    module Errors; end
  end
end
