# frozen_string_literal: true

require_relative 'elasticsearch/index'
require_relative 'elasticsearch/query_results'
require_relative 'elasticsearch/query_builder'

module JayAPI
  # Fetches the previous software version depending on the given version.
  class PriorVersionFetcherBase
    attr_reader :client

    # @param [JayAPI::Elasticsearch::Client] client The +Client+ object to use
    #   when connecting to Elasticsearch to execute queries.
    # @param [String] index_name The index of the build properties in Jay
    def initialize(client:, index_name:)
      @client = client
      @index_name = index_name
    end

    # Calculates the prior software version given the current version if
    # it exists.
    # @param [String] current_version The version for which to find a prior
    #   version.
    # @return [String, nil] the previous software version or nil if none is
    #   existent.
    def prior_version(current_version:)
      versions = []
      results = index_obj.search(query)

      results.all do |document|
        # Since the version is inside an array we have to call first
        versions << document['fields']['build_properties.version_code.keyword'].first
      end

      # This function must be injected by the project-specific fetcher
      compute_last_version(current_version: current_version, existent_versions: versions)
    end

    private

    attr_reader :cluster_url, :port, :index_name

    # Computes the last version using a predefined logic.
    # This function should be injected from the inheriting class, calling from
    # the base class will raise an error.
    # @param [String] current_version The current version for which the prior
    #   version should be computed.
    # @param [Array<Sting>] existent_versions An array containing versions which
    #   exist on JAY.
    # @raise [NotImplementedError] if called from the base class or the subclass
    #   has not overridden this method.
    def compute_last_version(current_version:, existent_versions:)
      raise NotImplementedError, "Please implement the method #{__method__} in #{self.class}!"
    end

    # @return [JayAPI::Elasticsearch::Index]
    def index_obj
      @index_obj ||= JayAPI::Elasticsearch::Index.new(client: client, index_name: index_name)
    end

    # @return [Hash] returns the query hash
    def query
      @query ||= JayAPI::Elasticsearch::QueryBuilder.new.collapse('build_properties.version_code.keyword').to_query
    end
  end
end
