# frozen_string_literal: true

require_relative '../errors/query_builder_error'
require_relative 'query_clause'
require_relative 'match_clauses'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents an Elasticsearch boolean query clause. For more information
        # about this type of clause check: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
        class Bool < JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          include ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchClauses

          def initialize
            @query_clauses = {}
          end

          # Adds a +must+ clause to the +bool+ clause.
          # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Yields itself if a block is given.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If no boolean clause currently exists.
          def must(&block)
            add_boolean_clause(:must, &block)
          end

          # Adds a +filter+ clause to an already existing +bool+ clause.
          # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Yields itself if a block is given.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If no boolean clause currently exists.
          def filter(&block)
            add_boolean_clause(:filter, &block)
          end

          # Adds a +should+ clause to an already existing +bool+ clause.
          # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Yields itself if a block is given.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If no boolean clause currently exists.
          def should(&block)
            add_boolean_clause(:should, &block)
          end

          # Adds a +must_not+ clause to an already existing +bool+ clause.
          # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Yields itself if a block is given.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If no boolean clause currently exists.
          def must_not(&block)
            add_boolean_clause(:must_not, &block)
          end

          # Adds a clause to the current sub-clause of the boolean clause.
          # @param [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause]
          #   query_clause The query clause to add.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If no boolean sub-clause has been defined.
          def <<(query_clause)
            unless current_bool
              raise ::JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
                    'Please call #must, #filter, #should or #must_not in order ' \
                    'to add query clauses inside a boolean clause'
            end

            current_bool << query_clause
            self
          end

          # @return [Hash] The Hash representation of the Query Clause
          def to_h
            unless query_clauses.any?
              raise ::JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
                    'A boolean clause has been defined but no boolean sub-clauses were added'
            end

            unless query_clauses.values.all?(&:any?)
              raise ::JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
                    'A boolean clause and a sub-clause were defined but no match clauses were added'
            end

            {
              bool: query_clauses.transform_values { |value| value.map(&:to_h) }
            }
          end

          # @return [self] A copy of the receiver and all match clauses attached
          #   to it.
          def clone
            self.class.new.tap do |copy|
              copy.query_clauses = query_clauses.transform_values do |array|
                array.map(&:clone)
              end
            end
          end

          # @param [Other] other Another +QueryClause+ object.
          # @return [self] The receiver, after having merged the given
          #   +QueryClause+ into itself.
          def merge!(other)
            if other.is_a?(self.class)
              merge_clauses(other)
            elsif other.is_a?(self.class.superclass)
              must << other.clone
            else
              raise_cannot_merge_error(other)
            end

            self
          end

          # @param [Other] other Another +QueryClause+ object.
          # @return [self] A new instance of the class with the merging of the
          #   receiver abd the given +QueryClause+ object.
          def merge(other)
            # This +if+ prevents the creation of a clone (which can be costly)
            # only for an +ArgumentError+ to be raised when +#merge!+ is called.
            if [self.class, self.class.superclass].any? { |klass| other.is_a?(klass) }
              clone.merge!(other)
            else
              raise_cannot_merge_error(other)
            end
          end

          protected

          attr_accessor :query_clauses # Used by #clone

          private

          attr_reader :current_bool

          # Adds the given +bool+ sub-clause
          # @param [Symbol] clause_type The type of clause to add (one of +must+,
          #   +filter+, +should+ or +must_not+)
          # @yield [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Yields itself if a block is given.
          # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool]
          #   Returns itself so that other methods can be chained.
          def add_boolean_clause(clause_type, &block)
            @current_bool = query_clauses[clause_type] ||= []
            yield self if block
            self
          end

          # Merges the boolean clauses of the given +Bool+ into the query
          # clauses of the receiver. Producing a union of both.
          # @param [self] other Another instance of the class.
          def merge_clauses(other)
            all_clauses = query_clauses.keys.union(other.query_clauses.keys)
            all_clauses.each do |clause|
              others_clauses = other.query_clauses.fetch(clause, [])

              query_clauses[clause] ||= []
              query_clauses[clause] += others_clauses.map(&:clone)
            end
          end

          # @raise [ArgumentError] Is always raised with the appropriate error message.
          def raise_cannot_merge_error(other)
            raise ArgumentError, "Cannot merge #{self.class} with #{other.class}"
          end
        end
      end
    end
  end
end
