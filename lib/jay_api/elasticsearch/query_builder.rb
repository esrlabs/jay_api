# frozen_string_literal: true

require_relative 'query_builder/aggregations'
require_relative 'query_builder/errors'
require_relative 'query_builder/query_clauses'
require_relative 'query_builder/script'

module JayAPI
  module Elasticsearch
    # A helper class to build simple and common queries for Elasticsearch.
    # Queries are created with the Elasticsearch Query DSL:
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
    class QueryBuilder
      # @return [JayAPI::Elasticsearch::QueryBuilder::Aggregations]
      attr_reader :aggregations

      # @return [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] The current
      #   set of query clauses
      attr_reader :query

      # Creates a new instance of the class.
      # A new instance of the class will produce an empty query.
      def initialize
        @from = nil
        @size = nil
        @source = nil
        @sort = {}
        @collapse = nil
        @query = ::JayAPI::Elasticsearch::QueryBuilder::QueryClauses.new
        @aggregations = JayAPI::Elasticsearch::QueryBuilder::Aggregations.new
      end

      # Adds a +from+ clause to the query.
      # @param [Integer] from The value for the from clause.
      # @return [QueryBuilder] itself so that other methods can be chained.
      def from(from)
        check_argument(from, 'from', Integer)
        check_positive_argument(from, 'from')
        @from = from
        self
      end

      # Adds a +size+ clause to the query.
      # @param [Integer] size The value for the size clause.
      # @return [QueryBuilder] itself so that other methods can be chained.
      def size(size)
        check_argument(size, 'size', Integer)
        check_positive_argument(size, 'size')
        @size = size
        self
      end

      # Adds a +sort+ clause to the query.
      # This method can be called with multiple fields at once or called
      # multiple times.
      #
      # Example:
      #
      #   query_builder.sort(name: 'asc', age: 'desc')
      #
      # or
      #
      #   query_builder.sort(name: 'asc')
      #   query_builder.sort(age: 'desc')
      #
      # Both will produce the same +sort+ clause.
      #
      # It is also possible to pass a Hash with advanced sorting options, for
      # example:
      #
      #   query_builder.sort(price: { order: :desc, missing: :_last })
      #
      # @param [Hash] sort A Hash whose keys are the name of the fields
      #   and whose values are either the direction of the sorting (+:asc+ or
      #   +:desc+) or a Hash with advanced sort options.
      # @see https://www.elastic.co/docs/reference/elasticsearch/rest-apis/sort-search-results
      # @return [QueryBuilder] itself so that other methods can be chained.
      def sort(sort)
        check_argument(sort, 'sort', Hash)
        @sort.merge!(
          sort.transform_values { |value| value.is_a?(Hash) ? value : { order: value } }
        )
        self
      end

      # Adds a +collapse+ clause to the query.
      # @param [String] field The field to use for collapsing the results.
      # @return [QueryBuilder] itself so that other methods can be chained.
      def collapse(field)
        check_argument(field, 'field', String)
        @collapse = field
        self
      end

      # Adds a +_source+ clause to the query.
      # @param [FalseClass, String, Array<String>, Hash] filter_expr Expression
      #   used for source filtering.
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/current/search-fields.html#source-filtering
      #   For more information on what kind of expressions are allowed.
      # @return [QueryBuilder] itself so that other methods can be chained.
      def source(filter_expr)
        check_argument(filter_expr, 'source', FalseClass, String, Array, Hash)
        @source = filter_expr
        self
      end

      # @return [Hash] The generated query.
      def to_h
        build_query
      end

      alias to_query to_h

      # Returns a new +QueryBuilder+ object which is the result of merging the
      # receiver with +other+.
      # @param [self] other Another instance of +QueryBuilder+.
      # @return [self] A new +QueryBuilder+, the result of the merge of both
      #   objects.
      # @raise [TypeError] If the given object is not a +QueryBuilder+.
      def merge(other)
        klass = self.class
        raise TypeError, "Cannot merge #{klass} and #{other.class}" unless other.is_a?(klass)

        other.combine(
          from: @from, size: @size, source: @source, collapse: @collapse,
          sort: @sort, query: @query, aggregations: @aggregations
        )
      end

      # @return [JayAPI::Elasticsearch::QueryBuilder] A copy of the receiver.
      def clone
        copy = super
        copy.source = @source.clone # source can be an Array or a Hash
        copy.sort = @sort.clone     # sort is a Hash
        copy.query = query.clone
        copy.aggregations = aggregations.clone
        copy
      end

      protected

      attr_writer :from, :size, :source, :collapse, :sort, :query, :aggregations

      # Creates a new +QueryBuilder+ object whose attributes are a combination
      # of the receiver's attributes and the provided values. The receiver's
      # attributes take precedence over the given ones.
      # @param [Integer, nil] from See {#from}
      # @param [Integer, nil] size See {#size}
      # @param [String, nil] source See {#source}
      # @param [String, nil] collapse See {#collapse}
      # @param [Hash] sort See {#sort}
      # @param [JayAPI::Elasticsearch::QueryBuilder::QueryClauses] query See {#query}
      # @param [JayAPI::Elasticsearch::QueryBuilder::Aggregations] aggregations See {#aggregations}
      # @return [self] A new +QueryBuilder+ object.
      def combine(from:, size:, source:, collapse:, sort:, query:, aggregations:)
        self.class.new.tap do |combined|
          combined.from = @from || from
          combined.size = @size || size
          # TODO: Improve the merging of this kind of clause (https://esrlabs.atlassian.net/browse/JAY-495)
          combined.source = @source || source
          combined.collapse = @collapse || collapse
          combined.sort = sort.merge(@sort)
          combined.query = query.merge(self.query)
          combined.aggregations = aggregations.merge(self.aggregations)
        end
      end

      private

      # :reek:FeatureEnvy (cannot be avoided, is checking the argument)
      # Checks that the given argument is an instance of the specified class.
      # @param [Object] value The value of the argument.
      # @param [String] argument_name The name of the argument (for the error
      #   message).
      # @param [Class, Array<Class>] allowed_types The list of classes that
      #   +value+ might have.
      # @raise [ArgumentError] If the value is not an instance of the any of the
      #   classes in +allowed_types+.
      def check_argument(value, argument_name, *allowed_types)
        return if allowed_types.any? { |allowed_type| value.is_a?(allowed_type) }

        raise ArgumentError, "Expected `#{argument_name}` to be one of: " \
                             "#{allowed_types.map(&:to_s).join(', ')} but #{value.class} was given"
      end

      # Checks that the given argument is positive (>= 0)
      # @param [Numeric] value The value of the argument.
      # @param [String] argument_name The name of the argument (for the error
      #   message).
      # @raise [ArgumentError] If the value is not positive.
      def check_positive_argument(value, argument_name)
        return if value >= 0

        raise ArgumentError, "`#{argument_name}` should be a positive integer"
      end

      # Builds the query.
      # @return [Hash] The Elasticsearch DSL Query.
      def build_query
        query_hash = {}
        query_hash[:from] = @from if @from
        query_hash[:size] = @size if @size
        query_hash[:_source] = @source unless @source.nil?
        query_hash[:query] = query.to_h

        query_hash[:sort] = @sort.map { |field, ordering| { field => ordering } } if @sort.any?

        if @collapse
          query_hash[:collapse] = {
            field: @collapse
          }
        end

        query_hash.merge(aggregations.to_h)
      end
    end
  end
end
