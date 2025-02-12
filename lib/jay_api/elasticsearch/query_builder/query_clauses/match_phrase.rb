# frozen_string_literal: true

require_relative 'query_clause'

module JayAPI
  module Elasticsearch
    class QueryBuilder
      class QueryClauses
        # Represents a Match Phrase query in Elasticsearch
        # Documentation for this type of query can be found here:
        # https://www.elastic.co/guide/en/elasticsearch/reference/7.9/query-dsl-match-query-phrase.html#query-dsl-match-query-phrase
        class MatchPhrase < ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause
          attr_reader :field, :phrase

          # @param [String] field The name of the field to match against
          # @param [String] phrase The phrase to match
          def initialize(field:, phrase:)
            @field = field
            @phrase = phrase
          end

          # @return [Hash] The Hash representation of the Query Clause (in
          #   Elasticsearch's format)
          def to_h
            {
              match_phrase: {
                field => phrase
              }
            }
          end
        end
      end
    end
  end
end
