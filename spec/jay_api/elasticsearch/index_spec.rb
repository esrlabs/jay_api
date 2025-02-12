# frozen_string_literal: true

require 'jay_api/elasticsearch/index'

RSpec.describe JayAPI::Elasticsearch::Index do
  subject(:index) { described_class.new(**params) }

  let(:base_params) do
    {
      index_name: index_name,
      client: mocked_elasticsearch
    }
  end

  let(:params) { base_params }

  let(:index_name) { 'elite_unit_tests' }

  let(:successful_response) do
    {
      'took' => 152,
      'errors' => false,
      'items' => [{
        'index' => {
          '_index' => index_name,
          '_type' => 'nested',
          '_id' => 'gHKq628BVvaJMVLXnxsb',
          '_version' => 1,
          'result' => 'created',
          '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
          '_seq_no' => 1,
          '_primary_term' => 1,
          'status' => 201
        }
      }]
    }
  end

  let(:response) { {} }
  let(:mocked_elasticsearch) do
    instance_double(
      JayAPI::Elasticsearch::Client,
      bulk: successful_response,
      search: response
    )
  end

  # rubocop:disable RSpec/VerifiedDoubles (Does not work with Logging because of meta-programming)
  let(:mocked_logger) do
    double(
      Logging::Logger,
      info: true,
      error: true
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles

  let(:data) { { type: 'example', name: 'Test data example' } }

  before do
    allow(Logging.logger).to receive(:[]).and_return(mocked_logger)
  end

  describe '#initialize' do
    subject(:method_call) { index }

    context 'when no logger has been given' do
      it 'creates a Logger for the class' do
        expect(Logging.logger).to receive(:[]).with(described_class)
        method_call
      end
    end

    context 'when a logger has been given' do
      let(:params) do
        base_params.update(logger: mocked_logger)
      end

      it 'does not create a new logger' do
        expect(Logging.logger).not_to receive(:[])
        method_call
      end
    end
  end

  describe '#push' do
    let(:batch_size) { 2 }

    let(:expected_data) do
      {
        body: [
          {
            index: {
              _index: index_name,
              _type: 'nested',
              data: data
            }
          }
        ] * 2
      }
    end

    let(:params) do
      base_params.update(batch_size: batch_size)
    end

    it 'puts the data with the correct structure in the queue' do
      expect(mocked_elasticsearch).to receive(:bulk).with(expected_data)
      2.times { index.push(data) }
    end

    context 'when the amount of data is smaller than the batch size' do
      let(:batch_size) { 100 }

      it 'enqueues the data but does not push it to Elasticsearch' do
        expect(mocked_elasticsearch).not_to receive(:bulk)
        10.times { index.push(data) }
      end
    end

    context 'when the amount of data goes over the batch size' do
      let(:batch_size) { 5 }

      it 'pushes the data to Elasticsearch every time the batch size is hit' do
        expect(mocked_elasticsearch).to receive(:bulk).exactly(3).times
        15.times { index.push(data) }
      end
    end
  end

  describe '#index' do
    let(:successful_response) do
      {
        '_index' => 'xyz01_unit_test',
        '_type' => 'nested',
        '_id' => 'SVY1mJEBQ5CNFZM8Lodt',
        '_version' => 1,
        'result' => 'created',
        '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
        '_seq_no' => 0,
        '_primary_term' => 1
      }
    end

    before do
      allow(mocked_elasticsearch).to receive(:index).and_return(successful_response)
    end

    shared_examples_for '#index when no type is specified' do
      let(:expected_data) do
        {
          index: index_name,
          type: 'nested',
          body: data
        }
      end

      it 'sends the given data to Elasticsearch right away (with the "nested" type)' do
        expect(mocked_elasticsearch).to receive(:index).with(expected_data)
        method_call
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(successful_response)
      end
    end

    context 'when no type is specified' do
      subject(:method_call) { index.index(data) }

      it_behaves_like '#index when no type is specified'
    end

    context 'when type is specified as "nested"' do
      subject(:method_call) { index.index(data, type: 'nested') }

      it_behaves_like '#index when no type is specified'
    end

    context 'when type is set to nil' do
      subject(:method_call) { index.index(data, type: nil) }

      let(:expected_data) do
        {
          index: index_name,
          type: nil,
          body: data
        }
      end

      it "sends the given data to Elasticsearch right away (with 'type' set to nil)" do
        expect(mocked_elasticsearch).to receive(:index).with(expected_data)
        method_call
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(successful_response)
      end
    end

    context 'when type is set to an invalid value' do
      subject(:method_call) { index.index(data, type: 'flatten') }

      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(ArgumentError, "Unsupported type: 'flatten'")
      end
    end
  end

  describe '#queue_size' do
    subject(:method_call) { index.queue_size }

    let(:params) do
      base_params.update(batch_size: 15)
    end

    context 'with multiple items in the queue' do
      before do
        10.times { index.push(data) }
      end

      it 'returns the correct number of items' do
        expect(method_call).to eq(10)
      end
    end

    context 'with no items in the queue' do
      it 'returns 0' do
        expect(method_call).to eq(0)
      end
    end

    context 'when an item is pushed to the index' do
      it 'increases accordingly' do
        expect { index.push(data) }.to change(index, :queue_size).by(1)
      end
    end
  end

  describe '#flush' do
    subject(:method_call) { index.flush }

    let(:params) do
      base_params.update(batch_size: 5)
    end

    context 'when there is no data' do
      it 'does not try to push any data' do
        expect(mocked_elasticsearch).not_to receive(:bulk)
        method_call
      end
    end

    context 'when there is data in the buffer' do
      before { 3.times { index.push(data) } }

      it 'pushes the data currently held in the queue to Elasticsearch' do
        expect(mocked_elasticsearch).to receive(:bulk).once
        method_call
      end

      it 'clears the queue' do
        expect { method_call }.to change(index, :queue_size).from(3).to(0)
      end

      context 'when there is an error on the Elasticsearch instance' do
        let(:error_response) do
          {
            'took' => 9,
            'errors' => true,
            'items' => [
              {
                'index' => {
                  '_index' => index_name,
                  '_type' => 'nested',
                  '_id' => 'EExOS4cBrb-mrkbmwAGg',
                  'result' => 'created',
                  '_shards' => {
                    'total' => 2,
                    'successful' => 1,
                    'failed' => 0
                  },
                  'status' => 201
                }
              },
              {
                'index' => {
                  '_index' => index_name,
                  '_type' => 'nested',
                  '_id' => 'fnKi628BVvaJMVLXJxty',
                  'status' => 400,
                  'error' => {
                    'type' => 'illegal_argument_exception',
                    'reason' => 'mapper [test_env.report_meta.SUT tags.cluster] ' \
                                'of different type, current_type [long], merged_type [text]'
                  }
                }
              }
            ]
          }
        end

        let(:expected_message) do
          "An error occurred when pushing the data to Elasticsearch:\n" \
            '{"type"=>"illegal_argument_exception", "reason"=>' \
            '"mapper [test_env.report_meta.SUT tags.cluster] of ' \
            'different type, current_type [long], merged_type [text]"}'
        end

        before do
          allow(mocked_elasticsearch).to receive(:bulk).and_return(error_response)
        end

        it 'raises an error' do
          expect { method_call }.to raise_error(
            JayAPI::Elasticsearch::Errors::ElasticsearchError, expected_message
          )
        end
      end
    end
  end

  describe '#search' do
    subject(:method_call) { index.search(query, batch_counter: batch_counter) }

    let(:query) do
      {
        query: {
          query_string: {
            fields: ['test_case.identifier'],
            query: '"Elite::Tools::Jay::ElasticsearchIndex/#push/Puts the data with the correct structure in the queue"'
          }
        },
        sort: [
          {
            'test_case.finished_at.keyword': {
              order: 'desc'
            }
          }
        ]
      }
    end

    let(:expected_query) do
      {
        index: index_name,
        body: query
      }
    end

    let(:response) do
      {
        'took' => 1,
        'timed_out' => false,
        '_shards' => {
          'total' => 5,
          'successful' => 5,
          'skipped' => 0,
          'failed' => 0
        },
        'hits' => {
          'total' => {
            'value' => 33,
            'relation' => 'eq'
          },
          'max_score' => nil,
          'hits' => []
        }
      }
    end

    let(:response_object) { instance_double(JayAPI::Elasticsearch::Response, size: 33) }
    let(:batch_counter) { instance_double(JayAPI::Elasticsearch::BatchCounter) }

    before do
      allow(JayAPI::Elasticsearch::QueryResults).to receive(:new)
      allow(JayAPI::Elasticsearch::Response).to receive(:new).with(response).and_return(response_object)
      allow(JayAPI::Elasticsearch::BatchCounter).to receive(:create_or_update).with(batch_counter, query, 33)
                                                                              .and_return(batch_counter)
    end

    it 'sends the expected query to Elasticsearch' do
      expect(mocked_elasticsearch).to receive(:search).with(expected_query)
      method_call
    end

    context 'when Elasticsearch responds with an error' do
      let(:expected_error) { Elasticsearch::Transport::Transport::Errors::BadRequest }

      let(:expected_log) do
        <<~TEXT
          The 'search' query is invalid: {
            "query": {
              "query_string": {
                "fields": [
                  "test_case.identifier"
                ],
                "query": "\\"Elite::Tools::Jay::ElasticsearchIndex/#push/Puts the data with the correct structure in the queue\\""
              }
            },
            "sort": [
              {
                "test_case.finished_at.keyword": {
                  "order": "desc"
                }
              }
            ]
          }
        TEXT
      end

      before do
        allow(mocked_elasticsearch).to receive(:search)
          .and_raise(expected_error)
      end

      it 'raises the error to the caller' do
        expect { method_call }.to raise_error(expected_error)
      end

      it 'logs the query which caused the error message' do
        expect(mocked_logger).to receive(:error).with(expected_log.strip)

        expect { method_call }.to raise_error(expected_error)
      end
    end

    context 'when Elasticsearch responds with a valid response' do
      context "without 'search_after' type parameter in the options" do
        it 'creates a new instance of the QueryResults class and passes the response' do
          expect(JayAPI::Elasticsearch::QueryResults)
            .to receive(:new).with(index: index, query: query, response: response_object, batch_counter: batch_counter)

          method_call
        end
      end

      context "with 'search_after' type parameter in the options" do
        subject(:method_call) { index.search(query, batch_counter: batch_counter, type: :search_after) }

        before do
          allow(JayAPI::Elasticsearch::SearchAfterResults).to receive(:new)
        end

        it 'creates a new instance of the SearchAfterResults class and passes the response' do
          expect(JayAPI::Elasticsearch::SearchAfterResults)
            .to receive(:new).with(index: index, query: query, response: response_object, batch_counter: batch_counter)

          method_call
        end
      end
    end
  end

  describe '#delete_by_query' do
    subject(:method_call) { index.delete_by_query(query) }

    let(:query) do
      {
        bool: {
          must: [
            query_string: {
              query: '"test_case.id_long: "Qualification Tests/Diagnostics/OBD/*"'
            },
            range: {
              field: 'test_case.finished_at',
              gte: '2024/02/07 18:00:00',
              lte: '2024/02/09 13:00:00'
            }
          ]
        }
      }
    end

    let(:successful_response) do
      {
        'took' => 103,
        'timed_out' => false,
        'total' => 76,
        'deleted' => 76,
        'batches' => 1,
        'version_conflicts' => 0,
        'noops' => 0,
        'retries' => { 'bulk' => 0, 'search' => 0 },
        'throttled_millis' => 0,
        'requests_per_second' => 1.0,
        'throttled_until_millis' => 0,
        'failures' => []
      }
    end

    before do
      allow(mocked_elasticsearch).to receive(:delete_by_query).and_return(successful_response)
    end

    it 'relays the command to the Elasticsearch client' do
      expect(mocked_elasticsearch).to receive(:delete_by_query).with(
        index: index_name, body: query
      )

      method_call
    end

    context 'when a custom number of slices is to be used' do
      subject(:method_call) { index.delete_by_query(query, slices: 5) }

      it 'relays the command to the Elasticsearch client' do
        expect(mocked_elasticsearch).to receive(:delete_by_query).with(
          index: index_name, body: query, slices: 5
        )

        method_call
      end
    end

    context 'when the client should not wait for completion' do
      subject(:method_call) { index.delete_by_query(query, wait_for_completion: false) }

      it 'relays the command to the Elasticsearch client' do
        expect(mocked_elasticsearch).to receive(:delete_by_query).with(
          index: index_name, body: query, wait_for_completion: false
        )

        method_call
      end
    end

    context 'when the client should not wait for completion and should use a custom number of slices' do
      subject(:method_call) { index.delete_by_query(query, slices: 5, wait_for_completion: false) }

      it 'relays the command to the Elasticsearch client' do
        expect(mocked_elasticsearch).to receive(:delete_by_query).with(
          index: index_name, body: query, slices: 5, wait_for_completion: false
        )

        method_call
      end
    end

    context 'when the deletion succeeds' do
      context 'when the deletion has been executed synchronously (i.e., `wait_for_completion` is `true`)' do
        let(:expected_hash) do
          {
            took: 103,
            timed_out: false,
            total: 76,
            deleted: 76,
            batches: 1,
            version_conflicts: 0,
            noops: 0,
            retries: { bulk: 0, search: 0 },
            throttled_millis: 0,
            requests_per_second: 1.0,
            throttled_until_millis: 0,
            failures: []
          }
        end

        it 'returns the expected Hash' do
          expect(method_call).to eq(expected_hash)
        end
      end

      context 'when the deletion has been executed asynchronously (i.e., `wait_for_completion` is `false`)' do
        subject(:method_call) { index.delete_by_query(query, wait_for_completion: false) }

        let(:successful_response) do
          {
            'task' => 'B5oDyEsHQu2Q-wpbaMSMTg:577388264'
          }
        end

        let(:expected_hash) do
          {
            task: 'B5oDyEsHQu2Q-wpbaMSMTg:577388264'
          }
        end

        it 'returns the expected Hash' do
          expect(method_call).to eq(expected_hash)
        end
      end
    end

    context 'when the deletion fails' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Unauthorized,
          '[401] Unauthorized'
        ]
      end

      before do
        allow(mocked_elasticsearch).to receive(:delete_by_query).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end
  end

  describe '#delete_by_query_async' do
    subject(:method_call) { index.delete_by_query_async(query, slices: 5) }

    let(:query) do
      {
        bool: {
          must: [
            range: { field: 'test_case.finished_at', gte: '2024/02/07 18:00:00', lte: '2024/02/09 13:00:00' }
          ]
        }
      }
    end

    let(:async) do
      instance_double(
        JayAPI::Elasticsearch::Async,
        delete_by_query: response
      )
    end

    let(:response) do
      {}
    end

    before do
      allow(JayAPI::Elasticsearch::Async).to receive(:new).and_return(async)
    end

    it 'creates the expected Async object' do
      expect(JayAPI::Elasticsearch::Async).to receive(:new).with(index)
      method_call
    end

    it 'makes the Async object delete by query' do
      expect(async).to receive(:delete_by_query).with(query, slices: 5)
      method_call
    end

    it 'returns what the Async object returns when deleting by query' do
      expect(method_call).to eq(response)
    end
  end
end
