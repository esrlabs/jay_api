# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'

module JayAPI
  module Elasticsearch
    # Represents Elasticsearch tasks. Returns information about the tasks
    # currently executing in the cluster.
    # TODO: Add #all [JAY-593]
    class Tasks
      attr_reader :client

      # @param [JayAPI::Elasticsearch::Client] client The Elasticsearch Client
      #   object
      def initialize(client:)
        @client = client
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
        client.task_by_id(task_id: task_id, wait_for_completion: true).deep_symbolize_keys
      end
    end
  end
end
