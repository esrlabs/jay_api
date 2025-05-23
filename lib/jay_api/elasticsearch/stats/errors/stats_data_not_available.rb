# frozen_string_literal: true

require_relative '../../../errors/error'

module JayAPI
  module Elasticsearch
    class Stats
      module Errors
        # An error to be raised when a particular Stats element is requested for
        # which there is no data in the response received from the cluster.
        class StatsDataNotAvailable < ::JayAPI::Errors::Error; end
      end
    end
  end
end
