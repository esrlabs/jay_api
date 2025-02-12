# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # This is the base class for all the query types that Elasticsearch can
        # handle. See the subclasses for info on each of the query types.
        class QueryClause
          def to_h
            raise NotImplementedError, "Please implement the #to_h method in the #{self.class} class"
          end
        end
      end
    end
  end
end
