# frozen_string_literal: true

require 'jay_api/elasticsearch/indexes'

require_relative 'indexable_shared'

RSpec.describe JayAPI::Elasticsearch::Indexes do
  subject(:indexes) { described_class.new(**constructor_params) }

  let(:constructor_params) do
    {
      index_names: index_names,
      client: client
    }
  end

  let(:index_names) { %w[xyz01_integration_test xyz01_unit_test xyz01_traceability] }

  let(:successful_response) do
    {
      'took' => 152,
      'errors' => false,
      'items' => [
        {
          'index' => {
            '_index' => 'xyz01_integration_test',
            '_type' => 'nested',
            '_id' => 'gHKq628BVvaJMVLXnxsb',
            '_version' => 1,
            'result' => 'created',
            '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
            '_seq_no' => 1,
            '_primary_term' => 1,
            'status' => 201
          }
        },
        {
          'index' => {
            '_index' => 'xyz01_unit_test',
            '_type' => 'nested',
            '_id' => 'gHKq628BVvaJMVLXnxsb',
            '_version' => 1,
            'result' => 'created',
            '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
            '_seq_no' => 1,
            '_primary_term' => 1,
            'status' => 201
          }
        },
        {
          'index' => {
            '_index' => 'xyz01_traceability',
            '_type' => 'nested',
            '_id' => 'gHKq628BVvaJMVLXnxsb',
            '_version' => 1,
            'result' => 'created',
            '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
            '_seq_no' => 1,
            '_primary_term' => 1,
            'status' => 201
          }
        }
      ]
    }
  end

  let(:data) { { type: 'example', name: 'Test data example' } }

  include_context 'with mocked objects for Elasticsearch::Indexable'

  it 'does not respond to #index_name' do
    expect(indexes).not_to respond_to(:index_name)
  end

  describe '#initialize' do
    subject(:method_call) { indexes }

    shared_examples_for '#initialize when the batch_size is not a multiple of the number of indexes' do
      it 'logs a warning telling the user that the batch size might be overshot' do
        expect(mocked_logger).to receive(:warn).with(
          "'batch_size' is not a multiple of the number of elements in 'index_names'. " \
          "This can lead to a _bulk size slightly bigger than 'batch_size'"
        )

        method_call
      end
    end

    context 'when the batch size is not specified' do
      it_behaves_like 'Indexable#initialize'

      it_behaves_like '#initialize when the batch_size is not a multiple of the number of indexes'
    end

    context 'when the batch size is not a multiple of the number of indexes' do
      let(:constructor_params) { super().merge(batch_size: 10) }

      it_behaves_like 'Indexable#initialize'

      it_behaves_like '#initialize when the batch_size is not a multiple of the number of indexes'
    end

    context 'when the batch size is a multiple of the number of indexes' do
      let(:constructor_params) { super().merge(batch_size: 15) }

      it 'does not log any warnings' do
        expect(mocked_logger).not_to receive(:warn)
        method_call
      end

      it_behaves_like 'Indexable#initialize'
    end
  end

  describe '#index_names' do
    let(:method_call) { indexes.index_names }

    it 'returns the expected value (the index names passed to the class constructor)' do
      expect(method_call).to eq(%w[xyz01_integration_test xyz01_unit_test xyz01_traceability])
    end
  end

  describe '#push' do
    subject(:method_call) { described_method.call }

    # Needed in order to be able to repeat the method call
    let(:described_method) { -> { indexes.push(data) } }

    let(:constructor_params) do
      super().merge(batch_size: 15)
    end

    let(:expected_data) do
      {
        body: index_names.cycle(5).map do |index_name|
          {
            index: {
              _index: index_name,
              _type: 'nested',
              data: data
            }
          }
        end
      }
    end

    context 'when the amount of data is smaller than the batch size' do
      it 'enqueues the data but does not push it to Elasticsearch' do
        expect(client).not_to receive(:bulk)
        3.times { described_method.call }
      end
    end

    context 'when the amount of data matches the batch size' do
      it 'puts the data with the correct structure in the queue' do
        expect(client).to receive(:bulk).with(expected_data)
        5.times { described_method.call }
      end

      it 'leaves the queue empty' do
        5.times { described_method.call }
        expect(indexes.queue_size).to be_zero
      end
    end

    context 'when the amount of data goes over the batch size' do
      it 'pushes the data to Elasticsearch every time the batch size is hit' do
        expect(client).to receive(:bulk).with(expected_data).exactly(3).times
        15.times { described_method.call }
      end
    end
  end

  describe '#index' do
    subject(:method_call) { indexes.index(data, **method_params) }

    let(:method_params) { {} }

    let(:responses) do
      index_names.map do |index_name|
        {
          '_index' => index_name,
          '_type' => 'nested',
          '_id' => 'SVY1mJEBQ5CNFZM8Lodt',
          '_version' => 1,
          'result' => 'created',
          '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
          '_seq_no' => 0,
          '_primary_term' => 1
        }
      end
    end

    let(:successful_response) do
      [
        {
          '_index' => 'xyz01_integration_test',
          '_type' => 'nested',
          '_id' => 'SVY1mJEBQ5CNFZM8Lodt',
          '_version' => 1,
          'result' => 'created',
          '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
          '_seq_no' => 0,
          '_primary_term' => 1
        },
        {
          '_index' => 'xyz01_unit_test',
          '_type' => 'nested',
          '_id' => 'SVY1mJEBQ5CNFZM8Lodt',
          '_version' => 1,
          'result' => 'created',
          '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
          '_seq_no' => 0,
          '_primary_term' => 1
        },
        {
          '_index' => 'xyz01_traceability',
          '_type' => 'nested',
          '_id' => 'SVY1mJEBQ5CNFZM8Lodt',
          '_version' => 1,
          'result' => 'created',
          '_shards' => { 'total' => 2, 'successful' => 1, 'failed' => 0 },
          '_seq_no' => 0,
          '_primary_term' => 1
        }
      ]
    end

    before do
      allow(client).to receive(:index).and_return(*responses)
    end

    shared_examples_for '#index when no type is specified' do
      let(:expected_data) do
        {
          type: 'nested',
          body: data
        }
      end

      it 'sends the given data to the first Elasticsearch index (with the "nested" type)' do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_unit_test'))
        method_call
      end

      it 'sends the given data to the second Elasticsearch index (with the "nested" type)' do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_integration_test'))
        method_call
      end

      it 'sends the given data to the third Elasticsearch index (with the "nested" type)' do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_traceability'))
        method_call
      end

      it 'returns the expected Array of hashes' do
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
          type: nil,
          body: data
        }
      end

      it "sends the given data to the first Elasticsearch index (with 'type' set to nil)" do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_unit_test'))
        method_call
      end

      it "sends the given data to the second Elasticsearch index (with 'type' set to nil)" do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_integration_test'))
        method_call
      end

      it "sends the given data to the third Elasticsearch index (with 'type' set to nil)" do
        expect(client).to receive(:index).with(expected_data.merge(index: 'xyz01_traceability'))
        method_call
      end

      it 'returns the expected Array of hashes' do
        expect(method_call).to eq(successful_response)
      end
    end

    it_behaves_like 'Indexable#index'
  end

  describe '#queue_size' do
    subject(:method_call) { indexes.queue_size }

    let(:indexable) { indexes }

    it_behaves_like 'Indexable#queue_size'
  end

  describe '#flush' do
    subject(:method_call) { indexes.flush }

    let(:indexable) { indexes }

    let(:error_response) do
      {
        'took' => 9,
        'errors' => true,
        'items' => [
          {
            'index' => {
              '_index' => 'xyz01_integration_test',
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
              '_index' => 'xyz01_unit_test',
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

    it_behaves_like 'Indexable#flush'
  end

  describe '#search' do
    subject(:method_call) { indexes.search(query, **method_params) }

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

    let(:method_params) { { batch_counter: batch_counter } }

    let(:indexable) { indexes }

    let(:expected_query) do
      {
        index: index_names,
        body: query
      }
    end

    it_behaves_like 'Indexable#search'
  end

  describe '#delete_by_query' do
    subject(:method_call) { indexes.delete_by_query(query, **method_params) }

    let(:method_params) { {} }

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

    it_behaves_like 'Indexable#delete_by_query'
  end

  describe '#delete_by_query_async' do
    subject(:method_call) { indexes.delete_by_query_async(query, slices: 5) }

    let(:query) do
      {
        bool: {
          must: [
            range: { field: 'test_case.finished_at', gte: '2024/02/07 18:00:00', lte: '2024/02/09 13:00:00' }
          ]
        }
      }
    end

    let(:indexable) { indexes }

    it_behaves_like 'Indexable#delete_by_query_async'
  end
end
