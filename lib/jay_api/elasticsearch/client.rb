# frozen_string_literal: true

require 'elasticsearch/api/namespace/tasks'
require 'elasticsearch/transport/transport/errors'
require 'faraday/error'
require 'forwardable'

require_relative '../abstract/connection'
require_relative 'stats'

module JayAPI
  module Elasticsearch
    # The JayAPI wrapper class over the Elastisearch::Client object. It mirrors
    # the object's API, but if one of the ERRORS is raised, this Wrapper class will
    # rescue the error up to a few times and re-try the connection. This way the
    # connection to Elasticsearch will be more robust.
    class Client
      extend Forwardable

      # The errors that, if raised, must cause a retry of the connection.
      ERRORS = [
        ::Elasticsearch::Transport::Transport::ServerError,
        Faraday::TimeoutError
      ].freeze

      # Subclasses of the +Elasticsearch::Transport::Transport::ServerError+
      # for which a retry doesn't make sense.
      NON_RETRIABLE_ERRORS = [
        ::Elasticsearch::Transport::Transport::Errors::BadRequest,
        ::Elasticsearch::Transport::Transport::Errors::Unauthorized,
        ::Elasticsearch::Transport::Transport::Errors::Forbidden,
        ::Elasticsearch::Transport::Transport::Errors::NotFound,
        ::Elasticsearch::Transport::Transport::Errors::MethodNotAllowed,
        ::Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
        ::Elasticsearch::Transport::Transport::Errors::NotImplemented
      ].freeze

      attr_reader :transport_client, :logger, :max_attempts, :wait_strategy

      # @return [Boolean] True if there is connectivity to the cluster, false otherwise.
      # @raise [Transport::Errors::Forbidden] If the user has no permissions to
      #   ping the cluster.
      def_delegator :transport_client, :ping

      # @param [Elasticsearch::Transport::Client] transport_client The Client
      #   object that will be wrapped.
      # @param [Logging::Logger] logger
      # @param [Integer] max_attempts The maximum number of attempts that the connection shall be retried.
      # @param [JayAPI::Elasticsearch::WaitStrategy] wait_strategy The waiting strategy for reconnections.
      def initialize(transport_client, logger = nil, max_attempts:, wait_strategy:)
        @transport_client = transport_client
        @logger = logger || Logging.logger($stdout)
        @max_attempts = max_attempts
        @wait_strategy = wait_strategy
      end

      # Calls the Elasticsearch::Client's #index method and retries the connection a few times if
      # a ServerError occurs.
      # @see Elasticsearch::Client#index for information about the arguments and the returned value.
      def index(**args)
        retry_request { transport_client.index(**args) }
      end

      # Calls the Elasticsearch::Client's #search method and retries the connection a few times if
      # a ServerError occurs.
      # @see Elasticsearch::Client#index for information about the arguments and the returned value.
      def search(**args)
        retry_request { transport_client.search(**args) }
      end

      # Calls the Elasticsearch::Client's #bulk method and retries the connection a few times if
      # a ServerError occurs.
      # @see Elasticsearch::Client#index for information about the arguments and the returned value.
      def bulk(**args)
        retry_request { transport_client.bulk(**args) }
      end

      # Calls the +Elasticsearch::Client+'s #delete_by_query method forwarding
      # the given parameters. If the request fails additional retries will be
      # performed.
      # @see Elasticsearch::Client#delete_by_query for information about the
      #   arguments and the return value.
      def delete_by_query(**args)
        retry_request { transport_client.delete_by_query(**args) }
      end

      # Calls +Elasticsearch::Client+'s #tasks.get method forwarding the given
      # parameters. If the request fails, additional retries will be performed.
      # @see Elasticsearch::Client#tasks for more info about the arguments and
      #   the return value.
      def task_by_id(**args)
        retry_request { transport_client.tasks.get(**args) }
      end

      # @return [JayAPI::Elasticsearch::Stats] An instance of the +Stats+ class,
      #   which gives the caller access to Elasticsearch's Statistics API.
      def stats
        @stats ||= ::JayAPI::Elasticsearch::Stats.new(transport_client)
      end

      private

      # @param [Proc] block The block to execute.
      # @yieldreturn [Object] Whatever the block returns
      def retry_request(&block)
        Abstract::Connection.new(max_attempts: max_attempts, wait_strategy: wait_strategy.dup, logger: logger)
                            .retry(errors: ERRORS, except: NON_RETRIABLE_ERRORS, &block)
      end
    end
  end
end
