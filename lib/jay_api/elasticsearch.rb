# frozen_string_literal: true

require_relative 'elasticsearch/async'
require_relative 'elasticsearch/batch_counter'
require_relative 'elasticsearch/client'
require_relative 'elasticsearch/client_factory'
require_relative 'elasticsearch/errors'
require_relative 'elasticsearch/index'
require_relative 'elasticsearch/query_builder'
require_relative 'elasticsearch/query_results'
require_relative 'elasticsearch/response'
require_relative 'elasticsearch/search_after_results'
require_relative 'elasticsearch/stats'
require_relative 'elasticsearch/tasks'
require_relative 'elasticsearch/time'

module JayAPI
  # Namespace for all Elasticsearch related classes.
  module Elasticsearch; end
end
