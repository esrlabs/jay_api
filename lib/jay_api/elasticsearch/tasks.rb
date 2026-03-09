# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash/indifferent_access'
require 'forwardable'

require_relative 'mixins/retriable_requests'

module JayAPI
  module Elasticsearch
    # Represents Elasticsearch tasks. Returns information about the tasks
    # currently executing in the cluster.
    class Tasks
      extend Forwardable
      include ::JayAPI::Elasticsearch::Mixins::RetriableRequests

      attr_reader :client

      def_delegators :client, :transport_client, :max_attempts, :wait_strategy, :logger

      # @param [JayAPI::Elasticsearch::Client] client The Elasticsearch Client
      #   object
      def initialize(client:)
        @client = client
      end

      # Gets the list of tasks running on the Elasticsearch cluster.
      # For more information about this endpoint and the parameters please see:
      # https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-tasks-list
      # @param [Array<String>] actions A list of actions. Only tasks matching
      #   these actions will be returned, if no task matches the result will be
      #   empty.
      # @param [Boolean] detailed Whether or not the result should include task
      #   details or not.
      # @return [Hash] A hash with the list of tasks running on the
      #   Elasticsearch cluster.
      def all(actions: nil, detailed: false)
        # Needed because unlike many Elasticsearch methods Tasks#list doesn't
        # call #listify over +actions+.
        actions = actions&.then do |value|
          value.is_a?(Array) ? value.join(',') : value
        end

        retry_request do
          tasks_client.list({ actions:, detailed: }.compact_blank)
        end
      end

      # Retrieves info about the task with the passed +task_id+
      # For more information on how to build the query please refer to the
      # Elasticsearch DSL documentation:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html#tasks-api-query-params
      # @param [String] task_id The ID of the task whose info is needed
      # @return [Hash] A Hash that details the results of the operation defined
      #   by +task_id+
      # @example Returned Hash can be found in this method's unit tests
      # @raise [Elasticsearch::Transport::Transport::ServerError] If the
      #   query fails.
      def by_id(task_id)
        retry_request do
          tasks_client.get(task_id:, wait_for_completion: true).deep_symbolize_keys
        end
      end

      private

      # @return [Elasticsearch::API::Tasks::TasksClient] The client used to
      #   access tasks-related information.
      def tasks_client
        @tasks_client ||= transport_client.tasks
      end
    end
  end
end
