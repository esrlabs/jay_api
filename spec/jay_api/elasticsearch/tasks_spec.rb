# frozen_string_literal: true

require 'jay_api/elasticsearch/tasks'

RSpec.describe JayAPI::Elasticsearch::Tasks do
  subject(:tasks) { described_class.new(client: client) }

  let(:tasks_client) do
    instance_double(
      Elasticsearch::API::Tasks::TasksClient,
      get: transport_response
    )
  end

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client,
      tasks: tasks_client
    )
  end

  let(:client) do
    instance_double(
      JayAPI::Elasticsearch::Client,
      logger: instance_double(Logging::Logger),
      max_attempts: 10,
      transport_client:,
      wait_strategy: instance_double(JayAPI::Abstract::WaitStrategy)
    )
  end

  describe '#by_id' do
    subject(:method_call) { tasks.by_id(task_id) }

    let(:task_id) { 'B5oDyEsHQu2Q-wpbaMSMTg:577388264' }

    let(:transport_response) do
      {
        'completed' => true,
        'task' => {
          'node' => 'B5oDyEsHQu2Q-wpbaMSMTg',
          'id' => 577_411_212,
          'type' => 'transport',
          'action' => 'indices:data/write/delete/byquery',
          'status' => {
            'total' => 18,
            'updated' => 0,
            'created' => 0,
            'deleted' => 18,
            'batches' => 5,
            'version_conflicts' => 0,
            'noops' => 0,
            'retries' => { 'bulk' => 0, 'search' => 0 },
            'throttled_millis' => 0,
            'requests_per_second' => -1.0,
            'throttled_until_millis' => 0,
            'slices' => [
              { 'slice_id' => 0, 'total' => 171, 'updated' => 0, 'created' => 0, 'deleted' => 171, 'batches' => 1 },
              { 'version_conflicts' => 0, 'noops' => 0, 'retries' => { 'bulk' => 0, 'search' => 0 } },
              { 'throttled_millis' => 0, 'requests_per_second' => -1.0, 'throttled_until_millis' => 0 },
              { 'all_the_keys_above_are_present_in_each_shard' => 'but are split in 3 shards here for readability' }
            ]
          },
          'description' => 'delete-by-query [xyz01_unit_test]',
          'start_time_in_millis' => 1_732_194_640_676,
          'running_time_in_nanos' => 76_102_608,
          'cancellable' => true,
          'headers' => {}
        },
        'response' => {
          'took' => 49,
          'timed_out' => false,
          'total' => 18,
          'updated' => 0,
          'created' => 0,
          'deleted' => 18,
          'batches' => 5,
          'version_conflicts' => 0,
          'noops' => 0,
          'retries' => { 'bulk' => 0, 'search' => 0 },
          'throttled' => '0s',
          'throttled_millis' => 0,
          'requests_per_second' => -1.0,
          'throttled_until' => '0s',
          'throttled_until_millis' => 0,
          'slices' => [
            { 'slice_id' => 0, 'total' => 171, 'updated' => 0, 'created' => 0, 'deleted' => 171, 'batches' => 1 },
            { 'version_conflicts' => 0, 'noops' => 0, 'retries' => { 'bulk' => 0, 'search' => 0 } },
            { 'throttled_millis' => 0, 'requests_per_second' => -1.0, 'throttled_until_millis' => 0 },
            { 'all_the_keys_above_are_present_in_each_shard' => 'but are split in 3 shards here for readability' }
          ],
          'failures' => []
        }
      }
    end

    it 'gets the Transport::Client from the given Client' do
      expect(client).to receive(:transport_client).ordered
      expect(transport_client).to receive(:tasks).ordered
      method_call
    end

    it 'uses the TasksClient to fetch the task with the given ID' do
      expect(tasks_client).to receive(:get).with(task_id:, wait_for_completion: true).ordered
      method_call
    end

    context 'when the operation succeeds' do
      let(:expected_hash) do
        {
          completed: true,
          task: {
            node: 'B5oDyEsHQu2Q-wpbaMSMTg',
            id: 577_411_212,
            type: 'transport',
            action: 'indices:data/write/delete/byquery',
            status: {
              total: 18,
              updated: 0,
              created: 0,
              deleted: 18,
              batches: 5,
              version_conflicts: 0,
              noops: 0,
              retries: { bulk: 0, search: 0 },
              throttled_millis: 0,
              requests_per_second: -1.0,
              throttled_until_millis: 0,
              slices: [
                { slice_id: 0, total: 171, updated: 0, created: 0, deleted: 171, batches: 1 },
                { version_conflicts: 0, noops: 0, retries: { bulk: 0, search: 0 } },
                { throttled_millis: 0, requests_per_second: -1.0, throttled_until_millis: 0 },
                { all_the_keys_above_are_present_in_each_shard: 'but are split in 3 shards here for readability' }
              ]
            },
            description: 'delete-by-query [xyz01_unit_test]',
            start_time_in_millis: 1_732_194_640_676,
            running_time_in_nanos: 76_102_608,
            cancellable: true,
            headers: {}
          },
          response: {
            took: 49,
            timed_out: false,
            total: 18,
            updated: 0,
            created: 0,
            deleted: 18,
            batches: 5,
            version_conflicts: 0,
            noops: 0,
            retries: { bulk: 0, search: 0 },
            throttled: '0s',
            throttled_millis: 0,
            requests_per_second: -1.0,
            throttled_until: '0s',
            throttled_until_millis: 0,
            slices: [
              { slice_id: 0, total: 171, updated: 0, created: 0, deleted: 171, batches: 1 },
              { version_conflicts: 0, noops: 0, retries: { bulk: 0, search: 0 } },
              { throttled_millis: 0, requests_per_second: -1.0, throttled_until_millis: 0 },
              { all_the_keys_above_are_present_in_each_shard: 'but are split in 3 shards here for readability' }
            ],
            failures: []
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when the operation fails' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Unauthorized,
          '[401] Unauthorized'
        ]
      end

      before do
        allow(tasks_client).to receive(:get).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end
  end
end
