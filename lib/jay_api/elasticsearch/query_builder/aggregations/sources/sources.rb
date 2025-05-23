# frozen_string_literal: true

require_relative 'terms'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class Aggregations
        module Sources
          class Sources
            def terms(name, **kw_args)
              sources.push(::JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sources::Terms.new(name, **kw_args))
            end

            def to_h
              sources.map(&:to_h)
            end

            def clone
              self.class.new.tap do |copy|
                copy.sources.concat(sources.map(&:clone))
              end
            end

            protected

            def sources
              @sources ||= []
            end
          end
        end
      end
    end
  end
end
