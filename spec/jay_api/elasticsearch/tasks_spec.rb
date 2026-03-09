# frozen_string_literal: true

require 'jay_api/elasticsearch/tasks'

RSpec.describe JayAPI::Elasticsearch::Tasks do
  subject(:tasks) { described_class.new(client:) }

  let(:tasks_client) do
    instance_double(
      Elasticsearch::API::Tasks::TasksClient,
      get: transport_response,
      list: transport_response
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

  shared_examples_for '#tasks_client' do
    it 'gets the Transport::Client from the given Client' do
      expect(client).to receive(:transport_client).ordered
      expect(transport_client).to receive(:tasks).ordered
      method_call
    end
  end

  describe '#all' do
    subject(:method_call) { tasks.all(**method_params) }

    let(:method_params) { {} }

    let(:transport_response) do
      { 'nodes' =>
         { 'S13zyUneSa2Brl5XRNoD7Q' =>
            { 'name' => 'c8f5b1ae733a17bf05b35c66032e72e7',
              'roles' => %w[data ingest master remote_cluster_client],
              'tasks' =>
               { 'S13zyUneSa2Brl5XRNoD7Q:170466185' =>
                  { 'node' => 'S13zyUneSa2Brl5XRNoD7Q',
                    'id' => 170_466_185,
                    'type' => 'direct',
                    'action' => 'cluster:monitor/tasks/lists[n]',
                    'start_time_in_millis' => 1_773_072_735_568,
                    'running_time_in_nanos' => 13_000_011,
                    'cancellable' => false,
                    'cancelled' => false,
                    'parent_task_id' => 'S13zyUneSa2Brl5XRNoD7Q:170466184',
                    'headers' => {} },
                 'S13zyUneSa2Brl5XRNoD7Q:170466184' =>
                  { 'node' => 'S13zyUneSa2Brl5XRNoD7Q',
                    'id' => 170_466_184,
                    'type' => 'transport',
                    'action' => 'cluster:monitor/tasks/lists',
                    'start_time_in_millis' => 1_773_072_735_557,
                    'running_time_in_nanos' => 29_102_229,
                    'cancellable' => false,
                    'cancelled' => false,
                    'headers' => {} } } },
           '2MqUhOT_Sdi6ZJ8P04aUtg' =>
            { 'name' => '224b01c103d31d5f520636719d930944',
              'roles' => %w[data ingest master remote_cluster_client],
              'tasks' =>
               { '2MqUhOT_Sdi6ZJ8P04aUtg:80324869' =>
                  { 'node' => '2MqUhOT_Sdi6ZJ8P04aUtg',
                    'id' => 80_324_869,
                    'type' => 'transport',
                    'action' => 'cluster:monitor/tasks/lists[n]',
                    'start_time_in_millis' => 1_773_072_735_582,
                    'running_time_in_nanos' => 23_474_179,
                    'cancellable' => false,
                    'cancelled' => false,
                    'parent_task_id' => 'S13zyUneSa2Brl5XRNoD7Q:170466184',
                    'headers' => {} } } } } }
    end

    shared_examples_for '#all' do
      it 'directly returns the response' do
        expect(method_call).to be(transport_response)
      end
    end

    shared_examples_for '#all when no parameters are given' do
      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameter' do
        expect(tasks_client).to receive(:list).with({})
        method_call
      end

      it_behaves_like '#all'
    end

    context 'when no parameters are given' do
      let(:method_params) { {} }

      it_behaves_like '#all when no parameters are given'
    end

    context 'when actions are provided as a single string' do
      let(:method_params) { { actions: '*forcemerge' } }

      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameters' do
        expect(tasks_client).to receive(:list).with({ actions: '*forcemerge' })
        method_call
      end

      it_behaves_like '#all'
    end

    context 'when actions are provided as an array of strings' do
      let(:method_params) { { actions: %w[*forcemerge *byquery] } }

      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameters' do
        expect(tasks_client).to receive(:list).with({ actions: '*forcemerge,*byquery' })
        method_call
      end

      it_behaves_like '#all'
    end

    context 'when no tasks match the given actions' do
      let(:method_params) { { actions: %w[*ingest] } }

      let(:transport_response) do
        { 'nodes' => {} }
      end

      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameters' do
        expect(tasks_client).to receive(:list).with({ actions: '*ingest' })
        method_call
      end

      it_behaves_like '#all'
    end

    context "when 'detailed' is given as false" do
      let(:method_params) { { detailed: false } }

      it_behaves_like '#all when no parameters are given'
    end

    context "when 'detailed' is given as true" do
      let(:method_params) { { detailed: true } }

      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameters' do
        expect(tasks_client).to receive(:list).with({ detailed: true })
        method_call
      end

      it_behaves_like '#all'
    end

    context "when both 'actions' and 'detailed' are given" do
      let(:method_params) { { actions: '*forcemerge', detailed: true } }

      it_behaves_like '#tasks_client'

      it 'forwards the call to the Elasticsearch client, with the expected parameters' do
        expect(tasks_client).to receive(:list).with({ actions: '*forcemerge', detailed: true })
        method_call
      end

      it_behaves_like '#all'
    end
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

    it_behaves_like '#tasks_client'

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
