# frozen_string_literal: true

require 'jay_api/elasticsearch/tasks'

RSpec.describe JayAPI::Elasticsearch::Tasks do
  subject(:tasks) { described_class.new(client: client) }

  let(:client) do
    instance_double(
      JayAPI::Elasticsearch::Client
    )
  end

  describe '#by_id' do
    subject(:method_call) { tasks.by_id(task_id) }

    let(:task_id) { 'B5oDyEsHQu2Q-wpbaMSMTg:577388264' }

    let(:successful_response) do
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

    before do
      allow(client).to receive(:task_by_id).and_return(successful_response)
    end

    it 'relays the command to the Elasticsearch client' do
      expect(client).to receive(:task_by_id).with(task_id: task_id, wait_for_completion: true)
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
        allow(client).to receive(:task_by_id).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end
  end
end
