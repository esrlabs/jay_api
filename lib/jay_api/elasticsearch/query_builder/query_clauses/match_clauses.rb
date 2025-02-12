# frozen_string_literal: true

require_relative 'exists'
require_relative 'match_all'
require_relative 'match_none'
require_relative 'match_phrase'
require_relative 'query_string'
require_relative 'range'
require_relative 'regexp'
require_relative 'term'
require_relative 'terms'
require_relative 'wildcard'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Provides an easy interface to add query clauses to objects that behave
        # like query clauses sets.
        # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses
        # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool
        module MatchClauses
          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +MatchPhrase+ class.
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def match_phrase(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +QueryString+ class
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString#initialize
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def query_string(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Wildcard+ class
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard#initialize
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def wildcard(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Exists+ class'
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists#initialize
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def exists(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Term+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Term+ class'
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Term#initialize
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def term(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Term.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Range+ class'
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Rang#initialize
          # @return [self] Returns itself so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          # @raise [ArgumentError] If there are any issues with the parameters
          #   passed down to the +Range+ class's constructor.
          def range(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Terms+ class'
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms#initialize
          # @return [self] Returns itself, so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def terms(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp+
          # clause to the Query Clauses set.
          # @param [Hash] params The parameters for the +Regexp+ class'
          #   constructor.
          # @see JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp#initialize
          # @return [self] Returns itself, so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def regexp(**params)
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp.new(**params)
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll+
          # clause to the Query Clauses set.
          # @return [self] Returns itself, so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def match_all
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll.new
          end

          # Adds a +JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone+
          # clause to the Query Clauses set.
          # @return [self] Returns itself, so that other methods can be chained.
          # @raise [JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError]
          #   If an error occurs when trying to add the query clause to the set.
          def match_none
            self << ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone.new
          end
        end
      end
    end
  end
end
