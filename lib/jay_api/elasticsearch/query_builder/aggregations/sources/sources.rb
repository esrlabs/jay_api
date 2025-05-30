# frozen_string_literal: true

require_relative 'terms'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        module Sources
          # Represents the collection of sources for a Composite aggregation in
          # Elasticsearch
          class Sources
            # Adds a +terms+ source to the collection.
            # For information about the parameters:
            # @see Sources::Terms#initialize
            def terms(name, **kw_args)
              sources.push(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms.new(name, **kw_args))
            end

            # @return [Array<Hash>] Array representation of the collection of
            #   sources of the composite aggregation.
            def to_a
              sources.map(&:to_h)
            end

            # @return [self] A copy of the receiver (not a shallow clone, it
            #   clones all of the elements of the collection).
            def clone
              self.class.new.tap do |copy|
                copy.sources.concat(sources.map(&:clone))
              end
            end

            protected

            # @return [Array<Object>] The array used to hold the collection of
            #   sources.
            def sources
              @sources ||= []
            end
          end
        end
      end
    end
  end
end
