# frozen_string_literal: true

RSpec.shared_context 'with mocked objects for Elasticsearch::Indexable' do
  let(:response) { {} }

  let(:client) do
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

  before do
    allow(Logging.logger).to receive(:[]).and_return(mocked_logger)
  end
end

RSpec.shared_examples_for 'Indexable#initialize' do
  context 'when no logger has been given' do
    it 'creates a Logger for the class' do
      expect(Logging.logger).to receive(:[]).with(described_class)
      method_call
    end
  end

  context 'when a logger has been given' do
    let(:constructor_params) do
      super().merge(logger: mocked_logger)
    end

    it 'does not create a new logger' do
      expect(Logging.logger).not_to receive(:[])
      method_call
    end
  end
end

RSpec.shared_examples_for 'Indexable#push' do
  let(:constructor_params) do
    super().merge(batch_size: 10)
  end

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
      ] * 10
    }
  end

  context 'when the amount of data is smaller than the batch size' do
    it 'enqueues the data but does not push it to Elasticsearch' do
      expect(client).not_to receive(:bulk)
      5.times { described_method.call }
    end
  end

  context 'when the amount of data matches the batch size' do
    it 'puts the data with the correct structure in the queue' do
      expect(client).to receive(:bulk).with(expected_data)
      10.times { described_method.call }
    end
  end

  context 'when the amount of data goes over the batch size' do
    it 'pushes the data to Elasticsearch every time the batch size is hit' do
      expect(client).to receive(:bulk).with(expected_data).exactly(3).times
      30.times { described_method.call }
    end
  end
end

RSpec.shared_examples_for 'Indexable#index' do
  before do
    allow(client).to receive(:index).and_return(successful_response)
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
      expect(client).to receive(:index).with(expected_data)
      method_call
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(successful_response)
    end
  end

  context 'when no type is specified' do
    it_behaves_like '#index when no type is specified'
  end

  context 'when type is specified as "nested"' do
    let(:method_params) { { type: 'nested' } }

    it_behaves_like '#index when no type is specified'
  end

  context 'when type is set to nil' do
    let(:method_params) { { type: nil } }

    let(:expected_data) do
      {
        index: index_name,
        type: nil,
        body: data
      }
    end

    it "sends the given data to Elasticsearch right away (with 'type' set to nil)" do
      expect(client).to receive(:index).with(expected_data)
      method_call
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(successful_response)
    end
  end

  context 'when type is set to an invalid value' do
    let(:method_params) { { type: 'flatten' }  }

    it 'raises an ArgumentError' do
      expect { method_call }.to raise_error(ArgumentError, "Unsupported type: 'flatten'")
    end
  end
end

RSpec.shared_examples_for 'Indexable#queue_size' do
  let(:constructor_params) do
    super().merge(batch_size: 15)
  end

  context 'with no items have been pushed to the queue' do
    it 'returns 0' do
      expect(method_call).to eq(0)
    end
  end

  context 'when a single item is pushed to the index' do
    it 'increases accordingly' do
      expect { indexable.push(data) }.to change(indexable, :queue_size).by(1)
    end
  end

  context "when less than 'batch_size' items are pushed to the queue" do
    before do
      10.times { indexable.push(data) }
    end

    it 'returns the correct number of items' do
      expect(method_call).to eq(10)
    end
  end

  context "when 'batch_size' items are pushed to the index" do
    it 'goes back down to zero' do
      expect(client).to receive(:bulk).once # Checks that the items are pushed when the queue gets full.
      15.times { indexable.push(data) }
      expect(method_call).to be(0)
    end
  end

  context "when more than 'batch_size' items are pushed to the index" do
    it 'returns the expected number of items' do
      expect(client).to receive(:bulk).once # Checks that the items are pushed when the queue gets full.
      20.times { indexable.push(data) }
      expect(method_call).to be(5)
    end
  end
end

RSpec.shared_examples_for 'Indexable#flush' do
  let(:constructor_params) do
    super().merge(batch_size: 5)
  end

  context 'when there is no data' do
    it 'does not try to push any data' do
      expect(client).not_to receive(:bulk)
      method_call
    end
  end

  context 'when there is data in the buffer' do
    before { 3.times { indexable.push(data) } }

    it 'pushes the data currently held in the queue to Elasticsearch' do
      expect(client).to receive(:bulk).once
      method_call
    end

    it 'clears the queue' do
      expect { method_call }.to change(indexable, :queue_size).from(3).to(0)
    end

    context 'when there is an error on the Elasticsearch instance' do
      let(:expected_message) do
        "An error occurred when pushing the data to Elasticsearch:\n" \
          '{"type"=>"illegal_argument_exception", "reason"=>' \
          '"mapper [test_env.report_meta.SUT tags.cluster] of ' \
          'different type, current_type [long], merged_type [text]"}'
      end

      before do
        allow(client).to receive(:bulk).and_return(error_response)
      end

      it 'raises an error' do
        expect { method_call }.to raise_error(
          JayAPI::Elasticsearch::Errors::ElasticsearchError, expected_message
        )
      end
    end
  end
end

RSpec.shared_examples_for 'Indexable#search' do
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

    allow(JayAPI::Elasticsearch::BatchCounter).to receive(:create_or_update)
      .with(batch_counter, query, 33).and_return(batch_counter)
  end

  it 'sends the expected query to Elasticsearch' do
    expect(client).to receive(:search).with(expected_query)
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
      allow(client).to receive(:search).and_raise(expected_error)
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
        expect(JayAPI::Elasticsearch::QueryResults).to receive(:new)
          .with(index: indexable, query: query, response: response_object, batch_counter: batch_counter)

        method_call
      end
    end

    context "with 'search_after' type parameter in the options" do
      let(:method_params) { { batch_counter: batch_counter, type: :search_after } }

      before do
        allow(JayAPI::Elasticsearch::SearchAfterResults).to receive(:new)
      end

      it 'creates a new instance of the SearchAfterResults class and passes the response' do
        expect(JayAPI::Elasticsearch::SearchAfterResults).to receive(:new)
          .with(index: indexable, query: query, response: response_object, batch_counter: batch_counter)

        method_call
      end
    end
  end
end

RSpec.shared_examples_for 'Indexable#delete_by_query' do
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
    allow(client).to receive(:delete_by_query).and_return(successful_response)
  end

  it 'relays the command to the Elasticsearch client' do
    expect(client).to receive(:delete_by_query).with(
      index: index_name, body: query
    )

    method_call
  end

  context 'when a custom number of slices is to be used' do
    let(:method_params) { { slices: 5 } }

    it 'relays the command to the Elasticsearch client' do
      expect(client).to receive(:delete_by_query).with(
        index: index_name, body: query, slices: 5
      )

      method_call
    end
  end

  context 'when the client should not wait for completion' do
    let(:method_params) { { wait_for_completion: false } }

    it 'relays the command to the Elasticsearch client' do
      expect(client).to receive(:delete_by_query).with(
        index: index_name, body: query, wait_for_completion: false
      )

      method_call
    end
  end

  context 'when the client should not wait for completion and should use a custom number of slices' do
    let(:method_params) { { slices: 5, wait_for_completion: false } }

    it 'relays the command to the Elasticsearch client' do
      expect(client).to receive(:delete_by_query).with(
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
      let(:method_params) { { wait_for_completion: false } }

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

    context 'when the deletion fails' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Unauthorized,
          '[401] Unauthorized'
        ]
      end

      before do
        allow(client).to receive(:delete_by_query).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end
  end
end

RSpec.shared_examples_for 'Indexable#delete_by_query_async' do
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
    expect(JayAPI::Elasticsearch::Async).to receive(:new).with(indexable)
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
