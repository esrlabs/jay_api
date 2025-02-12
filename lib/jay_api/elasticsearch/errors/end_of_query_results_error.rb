# frozen_string_literal: true

require_relative 'elasticsearch_error'

module JayAPI
  module Elasticsearch
    module Errors
      # An error to be raised when an attempt is made to fetch more documents
      # on a QueryResults class that has reached the end of the matched
      # documents.
      class EndOfQueryResultsError < ElasticsearchError
        # :reek:ControlParameter (want to avoid the long string in as default value)
        # Creates a new instance of the class with the specified message.
        # @param [String] message The message to use, if none is given
        #   the default message will be used.
        def initialize(message = nil)
          super(message || 'End of the query results reached')
        end
      end
    end
  end
end
