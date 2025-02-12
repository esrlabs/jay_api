# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class QueryBuilder
      # Represents a scripted element in a query. This scripted element can be
      # used in different places. It can be used in a query clause, but can
      # also be used to create custom aggregations.
      class Script
        attr_reader :source, :lang, :params

        # @param [String] source The source for the script element.
        # @param [String] lang The language the script is written in.
        # @param [Hash] params A +Hash+ with key-value pairs for the script's
        #   parameters.
        def initialize(source:, lang: 'painless', params: nil)
          @source = source
          @lang = lang

          # Keeps the parameters from being modified from the outside after the
          # class has been initialized.
          @params = params.dup.freeze
        end

        # @return [Hash] The hash representation of the scripted element.
        def to_h
          {
            source: source,
            lang: lang,
            params: params
          }.compact
        end
      end
    end
  end
end
