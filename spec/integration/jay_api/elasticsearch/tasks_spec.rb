# frozen_string_literal: true

require 'jay_api/elasticsearch/tasks'

RSpec.describe JayAPI::Elasticsearch::Tasks do
  subject(:tasks) { described_class.new(client:) }

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client
    )
  end

  let(:wait_strategy) do
    JayAPI::Abstract::ConstantWait.new(wait_interval: 2)
  end

  let(:client) do
    JayAPI::Elasticsearch::Client.new(transport_client, max_attempts: 10, wait_strategy:)
  end

  describe '#by_id' do
    subject(:method_call) { tasks.by_id('S13zyUneSa2Brl5XRNoD7Q:170244912') }

    let(:response) do
      <<~JSON
        {
          "completed" : false,
          "task" : {
            "node" : "S13zyUneSa2Brl5XRNoD7Q",
            "id" : 170244912,
            "type" : "transport",
            "action" : "indices:data/write/delete/byquery",
            "status" : {
              "total" : 183950,
              "updated" : 0,
              "created" : 0,
              "deleted" : 42000,
              "batches" : 43,
              "version_conflicts" : 0,
              "noops" : 0,
              "retries" : {
                "bulk" : 0,
                "search" : 0
              },
              "throttled_millis" : 0,
              "requests_per_second" : -1.0,
              "throttled_until_millis" : 0
            },
            "description" : "delete-by-query [xyz01_integration_tests]",
            "start_time_in_millis" : 1773061157278,
            "running_time_in_nanos" : 8385740150,
            "cancellable" : true,
            "cancelled" : false,
            "headers" : { },
            "resource_stats" : {
              "total" : {
                "cpu_time_in_nanos" : 0,
                "memory_in_bytes" : 0
              }
            }
          }
        }
      JSON
    end

    let(:expected_hash) do
      {
        completed: false,
        task: {
          node: 'S13zyUneSa2Brl5XRNoD7Q',
          id: 170_244_912,
          type: 'transport',
          action: 'indices:data/write/delete/byquery',
          status: {
            total: 183_950,
            updated: 0,
            created: 0,
            deleted: 42_000,
            batches: 43,
            version_conflicts: 0,
            noops: 0,
            retries: { bulk: 0, search: 0 },
            throttled_millis: 0,
            requests_per_second: -1.0,
            throttled_until_millis: 0
          },
          description: 'delete-by-query [xyz01_integration_tests]',
          start_time_in_millis: 1_773_061_157_278,
          running_time_in_nanos: 8_385_740_150,
          cancellable: true,
          cancelled: false,
          headers: {},
          resource_stats: {
            total: { cpu_time_in_nanos: 0, memory_in_bytes: 0 }
          }
        }
      }
    end

    let(:tasks_client) do
      instance_double(
        Elasticsearch::API::Tasks::TasksClient,
        get: JSON.parse(response)
      )
    end

    before do
      allow(transport_client).to receive(:tasks).and_return(tasks_client)
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
