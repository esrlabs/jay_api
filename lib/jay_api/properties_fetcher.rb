# frozen_string_literal: true

require 'jay_api/errors/configuration_error'
require 'jay_api/elasticsearch/query_builder'

require_relative 'elasticsearch/time'

module JayAPI
  # Fetches build properties from the provided information. ATTENTION: There's
  # a maximum number of data hashes that are returned (see MAX_SIZE).
  class PropertiesFetcher
    include JayAPI::Elasticsearch::Time

    MAX_SIZE = 100

    # Name of the field used when querying the index for data using the name of
    # the build job.
    BUILD_NAME_FIELD = 'build_properties.build_name.keyword'
    BUILD_NUMBER_FIELD = 'build_properties.build_number'

    # Name of the field used when querying the index for data using the version
    # of the software.
    VERSION_CODE_FIELD = 'build_properties.version_code.keyword'
    BUILD_RELEASE_FIELD = 'build_properties.build_release'

    # Name of the field used when querying the index for data using the SUT Revision.
    SUT_REVISION_FIELD = 'sut_revision.keyword'
    TIMESTAMP_FIELD = 'timestamp'

    attr_reader :index

    # Initializes a PropertiesFetcher object
    # @param [JsyAPI::Elasticsearch::Index] index The Elasticsearch index to use
    #   to fetch build properties data.
    def initialize(index:)
      @index = index
    end

    # Constraints the results to those properties belonging to the given
    # SUT Revision.
    # @param [String] sut_revision For example: '23-08-02/master'.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def by_sut_revision(sut_revision)
      query_builder.query.bool.must.match_phrase(field: SUT_REVISION_FIELD, phrase: sut_revision)
      self
    end

    # Constraints the results to those properties belonging to the given build
    # job
    # @param [String] build_job The name of the build job, for example:
    #   'Release-XYZ01-Master'.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def by_build_job(build_job)
      query_builder.query.bool.must.match_phrase(field: BUILD_NAME_FIELD, phrase: build_job)
      self
    end

    # Constraints the results to those properties belonging to the given build
    # number
    # @param [String, Integer] build_number The build number, for example 432
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def by_build_number(build_number)
      query_builder.query.bool.must.query_string(fields: BUILD_NUMBER_FIELD, query: build_number)
      self
    end

    # Constraints the results to those properties for which the software version
    # matches the given one.
    # @param [String] software_version The software version, for example 'D310'.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def by_software_version(software_version)
      query_builder.query.bool.must.match_phrase(field: VERSION_CODE_FIELD, phrase: software_version)
      self
    end

    # Constraint the results to properties that belong or don't belong to
    # (depending on the +release_tag+ parameter) a release build.
    # @param [Boolean] release_tag True If build properties should come from a
    #   release, false if they SHOULD NOT.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def by_release_tag(release_tag)
      query_builder.query.bool.must.query_string(fields: BUILD_RELEASE_FIELD, query: release_tag)
      self
    end

    # Constraints the results to properties that were pushed after the given
    # +timestamp+.
    # @param [Time, String] timestamp A timestamp to filter the build properties
    #   with. If a +String+ is given it is assumed to be in the right format for
    #   Elasticsearch. No conversion / checking will be performed over it.
    # @return [JayAPI::PropertiesFetcher] itself, so that other methods can be
    #   chained.
    def after(timestamp)
      # noinspection RubyMismatchedParameterType (checked by the if modifier)
      timestamp = format_time(timestamp) if timestamp.is_a?(Time)
      query_builder.query.bool.must.query_string(fields: TIMESTAMP_FIELD, query: "> \"#{timestamp}\"")
      self
    end

    # Constraints the results to properties that were pushed before the given
    # +timestamp+.
    # @param [Time, String] timestamp A timestamp to filter the build properties
    #   with. If a +String+ is given it is assumed to be in the right format for
    #   Elasticsearch. No conversion / checking will be performed over it.
    # @return [JayAPI::PropertiesFetcher] itself, so that other methods can be
    #   chained.
    def before(timestamp)
      # noinspection RubyMismatchedParameterType (checked by the if modifier)
      timestamp = format_time(timestamp) if timestamp.is_a?(Time)
      query_builder.query.bool.must.query_string(fields: TIMESTAMP_FIELD, query: "< \"#{timestamp}\"")
      self
    end

    # This method is here only for readability. It is meant to act as a
    # conjunction between two method calls.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    # @example
    #   properties_fetcher.by_build_job('Release-XYZ01-Master').and.by_build_number(106)
    def and
      self
    end

    # @return [Hash, nil] The last set of properties (ordered chronologically)
    #   or +nil+ if no properties are found.
    def last
      sort_records('desc').size(1)
      fetch_properties.last
    end

    # @return [Hash, nil] The first set of properties (ordered chronologically)
    #   or +nil+ if no properties are found
    def first
      sort_records('asc').size(1)
      fetch_properties.first
    end

    # Limits the amount of records returned to the given number.
    # @param [Integer] size The number of records to return. If this number is
    #   greater than +MAX_SIZE+ then +MAX_SIZE+ will be used instead.
    # @return [JayAPI::PropertiesFetcher] Itself, so that other methods can be
    #   chained.
    def limit(size)
      size = [size, MAX_SIZE].min
      # noinspection RubyMismatchedParameterType (The array will never be empty)
      query_builder.size(size)
      self
    end

    alias size limit

    # Allows the caller to retrieve or iterate over the set of Build Properties
    # entries. The method can be called with or without a block. If a block is
    # given then each of the Build Properties entries will be yielded to the
    # block, if no block is given then an +Enumerator+ is returned.
    #
    # @yield [Hash] One of the Build Properties entries.
    # @return [Enumerator] If no block is given an +Enumerator+ object for all
    #   the property sets that were found is returned (might be empty). With a
    #   block the return value is undefined.
    def all(&block)
      fetch_properties.all(&block)
    end

    private

    # Fetches the properties given the provided query hash.
    # @return [QueryResults] The fetched data as a QueryResults object.
    def fetch_properties
      properties = index.search(query_builder.to_query)
      @query_builder = nil
      properties
    end

    # @return [JayAPI::Elasticsearch::QueryBuilder] The current QueryBuilder
    #   object. The QueryBuilder is only reset when records are fetched so that
    #   multiple conditions can be put together into it before the query is
    #   actually carried out.
    def query_builder
      @query_builder ||= JayAPI::Elasticsearch::QueryBuilder.new
    end

    # Adds a sort clause to the +QueryComposer+ object to sort the records
    # chronologically.
    # @param [String] direction The direction of the sorting, either +'asc'+ or
    #   +'desc'+
    def sort_records(direction)
      query_builder.sort('timestamp' => direction)
    end
  end
end
