# frozen_string_literal: true

require 'forwardable'

require_relative 'errors/query_builder_error'
require_relative 'query_clauses/bool'
require_relative 'query_clauses/match_clauses'
require_relative 'query_clauses/negator'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      # Represents the set of query clauses in an Elasticsearch query.
      # An empty set of clauses produces a "match all" query clause.
      class QueryClauses
        extend Forwardable

        include ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchClauses

        def_delegator :top_level_clause, :nil?, :empty?

        # Turns the query into a Compound Boolean query by adding a +bool+
        # clause and yields the latter so that sub-clauses can be added to it.
        # If the query is already a boolean query the current boolean clause is
        # yielded.
        # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
        #   If the query already has a top-level query.
        # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
        #   Yields the +bool+ query clause to the given block (if there is any).
        # @return [self, JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
        #   If a block is given then +self+ is returned, if no block is given
        #   then the +bool+ query clause is returned.
        def bool
          clause ||= boolean_clause || ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool.new
          replace_top_level_clause(clause, force: boolean_query?)

          if block_given?
            yield clause
            self
          else
            clause
          end
        end

        # Adds the given query clause as top-level clause if none exists yet.
        # @param [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause]
        #   query_clause The query clause to add.
        # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] Returns
        #   itself so that other methods can be chained.
        # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
        #   If there is already a top level clause.
        def <<(query_clause)
          replace_top_level_clause(query_clause)
        end

        # @return [Hash] The Hash representation of the Query Clauses set.
        # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
        #   If a boolean query was created but no inner clauses were added.
        def to_h
          return self.class.new.match_all.to_h if empty?

          top_level_clause.to_h
        end

        # @return [Boolean] True if the current Query Clauses set includes a
        #   +bool+ clause, false otherwise.
        def boolean_query?
          top_level_clause.is_a?(::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
        end

        # Clones the receiver and the enclosed top-level clause (if any).
        # @return [self] A copy of the receiver.
        def clone
          self.class.new.tap do |copy|
            copy << top_level_clause.clone
          end
        end

        # Creates a new +QueryClauses+ object by merging the receiver with the
        # given object. The individual top-query clauses are merged together
        # using a boolean clause.
        # @param [self] other The +QueryClauses+ object the receiver should be
        #   merged with.
        # @return [self] A new +QueryClauses+ object which is a combination of
        #   the receiver and the given object.
        def merge(other)
          klass = self.class
          raise TypeError, "Cannot merge #{klass} with #{other.class}" unless other.is_a?(klass)

          if other.empty?
            clone
          elsif empty?
            other.clone
          else
            klass.new.tap do |merged|
              merged.bool.merge!(top_level_clause).merge!(other.top_level_clause)
            end
          end
        end

        # Negates the receiver by wrapping its top-level query clause in a
        # +must_not+ boolean clause or replacing it by its inverse clause.
        # @return [self] Returns itself.
        def negate!
          if top_level_clause
            @top_level_clause = ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator.new(top_level_clause)
                                                                                            .negate
          else
            match_none
          end

          self
        end

        # @return [self] A negated version of the receiver (with its top-level
        #   query clause wrapped in a +must_not+ boolean query or replaced by
        #   its inverse clause)
        def negate
          clone.negate!
        end

        protected

        attr_reader :top_level_clause

        private

        # Replaces the current top-level clause with the given clause.
        # @param [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause]
        #   query_clause The query clause to add.
        # @param [Boolean] force Forces the replacement of the top-level clause
        #   even if there is already a top-level clause in place.
        # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] Returns
        #   itself so that other methods can be chained.
        # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
        #   If there is already a top level clause and +force+ is +false+.
        def replace_top_level_clause(query_clause, force: false)
          single_top_level_clause! unless force
          @top_level_clause = query_clause
          self
        end

        # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool, nil]
        #   The current top-level clause if it is a Boolean clause, +nil+
        #   otherwise.
        def boolean_clause
          boolean_query? ? top_level_clause : nil
        end

        # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
        #   If there is already a top level clause.
        def single_top_level_clause!
          return unless top_level_clause

          raise ::JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
                'Queries can only have one top-level query clause, ' \
                'to use multiple clauses add a compound query, ' \
                'for example: `bool`'
        end
      end
    end
  end
end
