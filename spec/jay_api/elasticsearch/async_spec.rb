# frozen_string_literal: true

require 'jay_api/elasticsearch/async'

RSpec.describe JayAPI::Elasticsearch::Async do
  subject(:async) { described_class.new(index) }

  let(:index) do
    instance_double(
      JayAPI::Elasticsearch::Index,
      index_name: 'xyz01_integration_test',
      delete_by_query: delete_by_query_response,
      client: client
    )
  end

  let(:tasks) do
    instance_double(
      JayAPI::Elasticsearch::Tasks,
      by_id: task_info_response
    )
  end

  let(:client) do
    instance_double(
      JayAPI::Elasticsearch::Client
    )
  end

  let(:delete_by_query_response) do
    {
      task: 'B5oDyEsHQu2Q-wpbaMSMTg:577388264'
    }
  end

  let(:task_info_response) do
    {
      completed: true,
      task: {
        description: 'delete-by-query [xyz01_unit_test]',
        there_are_many_more_fields_here: "more info in JayAPI::Elasticsearch::Tasks#by_id's tests"
      },
      response: {
        deleted: 94_662,
        failures: [],
        there_are_many_more_fields_here: "more info in JayAPI::Elasticsearch::Tasks#by_id's tests"
      }
    }
  end

  before do
    allow(JayAPI::Elasticsearch::Tasks).to receive(:new).and_return(tasks)
  end

  describe '#delete_by_query' do
    subject(:method_call) { async.delete_by_query(query, slices: 5) }

    let(:query) do
      {
        bool: {
          must: [
            range: { field: 'test_case.finished_at', gte: '2024/02/07 18:00:00', lte: '2024/02/09 13:00:00' }
          ]
        }
      }
    end

    let(:promise) do
      instance_double(
        Concurrent::Promise,
        value: task_info_response
      )
    end

    before do
      allow(Kernel).to receive(:sleep)

      # Simulate the execution of the block and mock what it returns
      allow(Concurrent::Promise).to receive(:execute).and_wrap_original do |&block|
        block.call
        promise
      end
    end

    it 'executes a concurrent promise' do
      expect(Concurrent::Promise).to receive(:execute).and_yield
      method_call
    end

    it 'asynchronously deletes the expected documents by query on the expected index' do
      expect(index).to receive(:delete_by_query).with(query, slices: 5, wait_for_completion: false)
      method_call
    end

    it 'initialises the expected Tasks object' do
      expect(JayAPI::Elasticsearch::Tasks).to receive(:new).with(client: client)
      method_call
    end

    it 'requests info about the task on the expected index' do
      expect(tasks).to receive(:by_id).with('B5oDyEsHQu2Q-wpbaMSMTg:577388264').once
      method_call
    end

    context 'when the task finishes successfully' do
      it 'returns a promise with the expected value' do
        expect(method_call).to be(promise)
        expect(method_call.value).to eq(task_info_response)
      end
    end

    context 'when the task times out' do
      let(:error_message) do
        '[500] {"error":{"root_cause":[{"type":"timeout_exception","reason":"Timed out waiting for completion of ' \
          '[org.elasticsearch.index.reindex.BulkByScrollTask@4f547604]"}],"type":"timeout_exception","reason":"Timed ' \
          'out waiting for completion of [org.elasticsearch.index.reindex.BulkByScrollTask@4f547604]"},"status":500}'
      end

      before do
        allow(tasks).to receive(:by_id).and_raise(
          Elasticsearch::Transport::Transport::Errors::InternalServerError, error_message
        )
      end

      it 'requests info about the task and raises the expected error' do
        expect(tasks).to receive(:by_id).with('B5oDyEsHQu2Q-wpbaMSMTg:577388264')
        expect { method_call }.to raise_error(
          Elasticsearch::Transport::Transport::Errors::InternalServerError, error_message
        )
      end
    end

    context 'when the task execution results in errors' do
      let(:task_info_response) do
        {
          completed: true,
          task: {
            description: 'delete-by-query [xyz01_unit_test]',
            there_are_many_more_fields_here: "more info in JayAPI::Elasticsearch::Tasks#by_id's tests"
          },
          error: {
            type: 'index_not_found_exception',
            reason: 'no such index [xyz01_unit_test]',
            'resource.type': 'index_or_alias',
            'resource.id': 'xyz01_unit_test',
            index_uuid: '_na_',
            index: 'xyz01_unit_test',
            suppressed: [
              {
                some: 'irrelevant stuff'
              }
            ]
          }
        }
      end

      let(:expected_message) do
        "Errors on index 'xyz01_integration_test':\n " \
          '{:type=>"index_not_found_exception", :reason=>"no such index [xyz01_unit_test]", ' \
          ':"resource.type"=>"index_or_alias", :"resource.id"=>"xyz01_unit_test", ' \
          ':index_uuid=>"_na_", :index=>"xyz01_unit_test", :suppressed=>[{:some=>"irrelevant stuff"}]}'
      end

      before do
        allow(tasks).to receive(:by_id).and_return(task_info_response)
      end

      it 'requests info about the task and raises the expected error' do
        expect(tasks).to receive(:by_id).with('B5oDyEsHQu2Q-wpbaMSMTg:577388264')
        expect { method_call }.to raise_error(JayAPI::Elasticsearch::Errors::QueryExecutionError, expected_message)
      end
    end

    context 'when the task execution results in failures' do
      let(:task_info_response) do
        {
          completed: true,
          task: {
            there_are_many_fields_here: "more info in JayAPI::Elasticsearch::Tasks#by_id's tests"
          },
          response: {
            failures: [
              {
                shard: 1,
                index: 'xyz01_integration_test',
                node: 'node-2',
                reason: {
                  type: 'resource_already_exists_exception',
                  reason: 'Document could not be deleted due to version conflict',
                  index_uuid: 'abc123',
                  shard: 1,
                  index: 'xyz01_integration_test'
                }
              }
            ],
            there_are_many_more_fields_here: "more info in JayAPI::Elasticsearch::Tasks#by_id's tests"
          }
        }
      end

      let(:expected_message) do
        "Failures on index 'xyz01_integration_test':\n " \
          '[{:shard=>1, :index=>"xyz01_integration_test", :node=>"node-2", :reason=>{:type=>' \
          '"resource_already_exists_exception", :reason=>"Document could not be deleted due to version conflict", ' \
          ':index_uuid=>"abc123", :shard=>1, :index=>"xyz01_integration_test"}}]'
      end

      before do
        allow(tasks).to receive(:by_id).and_return(task_info_response)
      end

      it 'requests info about the task and raises the expected error' do
        expect(tasks).to receive(:by_id).with('B5oDyEsHQu2Q-wpbaMSMTg:577388264')
        expect { method_call }.to raise_error(JayAPI::Elasticsearch::Errors::QueryExecutionFailure, expected_message)
      end
    end
  end
end
