# frozen_string_literal: true

require 'elasticsearch'
require 'logging'

require 'elasticsearch/transport/transport/errors'

require_relative 'client'
require_relative '../abstract/geometric_wait'
require_relative '../abstract/constant_wait'

module JayAPI
  module Elasticsearch
    # A factory class that creates an Elasticsearch Client object. More specifically, a JayAPI wrapper
    # object over the Elasticsearch Client object.
    class ClientFactory
      # The default port for the Elasticsearch cluster
      DEFAULT_ELASTICSEARCH_PORT = 9200

      # Classes that define the available waiting strategies, used for deciding sleep time between
      # the reconnections.
      WAIT_STRATEGIES = {
        geometric: JayAPI::Abstract::GeometricWait,
        constant: JayAPI::Abstract::ConstantWait
      }.freeze

      # The maximum number of connection attempts to be made.
      MAX_ATTEMPTS  = 4
      # The default wait time to be passed to the wait strategy class.
      WAIT_INTERVAL = 2

      attr_reader :cluster_url, :port

      # Creates a new instance of the class.
      # @param [String] cluster_url The URL where the Elasticsearch service
      #   is exposed.
      # @param [Integer] port The port to use to connect to the
      #   Elasticsearch instance (Needed only when different from the default
      #   Elasticsearch port)
      # @param [Logging::Logger] logger The logger object to use, if
      #   none is given a new one will be created.
      # @param [Hash] credentials
      # @option credentials [String] :username The user name to use when
      #   authenticating against the Elasticsearch instance.
      # @option credentials [String] :password The password to use when
      #   authenticating against the Elasticsearch instance.
      # disabling :reek:ControlParameter
      def initialize(cluster_url:, port: nil, logger: nil, **credentials)
        @cluster_url = cluster_url
        @port = port || DEFAULT_ELASTICSEARCH_PORT
        @logger = logger || Logging.logger($stdout)
        @username = credentials[:username]
        @password = credentials[:password]
      end

      # Returns the current instance of the Elasticsearch client, or creates
      # a new one.
      # @param [Integer] max_attempts The maximum number of attempts that the connection
      #   shall be retried.
      # @param [Symbol] wait_strategy The waiting strategy for reconnections (:geometric or :constant).
      # @param [Integer] wait_interval The wait interval for the wait strategy. The sleep time between
      #   each connection will be:
      #   * wait_interval with :constant wait strategy
      #   * wait_interval**i with :geometric wait strategy (where i is the i'th re-try)
      # @param [Integer] timeout The number of seconds to wait for Elasticsearch's
      #   response. For big queries that fetch large amounts of data the default
      #   timeout may be too low.
      # @return [JayAPI::Elasticsearch::Client] The Elasticsearch client.
      def create(max_attempts: MAX_ATTEMPTS, wait_strategy: :geometric, wait_interval: WAIT_INTERVAL, timeout: nil)
        JayAPI::Elasticsearch::Client.new(
          ::Elasticsearch::Client.new({
            hosts: [host],
            log: false,
            request_timeout: timeout
          }.compact),
          logger,
          max_attempts: max_attempts,
          wait_strategy: WAIT_STRATEGIES[wait_strategy].new(wait_interval: wait_interval, logger: logger)
        )
      end

      private

      attr_reader :logger, :username, :password

      # @return [URI] A URI constructed by parsing the given +cluster_url+.
      def cluster_uri
        @cluster_uri = URI.parse(cluster_url)
      end

      # @return [Hash] A +Hash+ with the connection parameters for the
      #   Elasticsearch instance.
      def host
        {}.tap do |host|
          host[:host] = cluster_uri.host
          host[:port] = port || DEFAULT_ELASTICSEARCH_PORT # Do not use cluster_uri.port, that will ALWAYS be defined.
          host[:user] = username if username
          host[:password] = password if password
          host[:scheme] = cluster_uri.scheme
        end
      end
    end
  end
end
