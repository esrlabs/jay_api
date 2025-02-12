# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    module Time
      # Time format accepted by elasticsearch
      TIME_FORMAT = '%Y/%m/%d %H:%M:%S'

      # Transforms a Time object to a time format that is recognized by
      # elasticsearch
      # @param [Time] time The time to convert
      # @return [String] The time converter to a string, parseable by ES
      def format_time(time)
        time.getutc.strftime(TIME_FORMAT)
      end
    end
  end
end
