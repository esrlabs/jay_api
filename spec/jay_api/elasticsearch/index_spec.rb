# frozen_string_literal: true

require 'jay_api/elasticsearch/index'

require_relative 'indexable_shared'

RSpec.describe JayAPI::Elasticsearch::Index do
  subject(:index) { described_class.new(**constructor_params) }

  let(:constructor_params) do
    {
      index_name: index_name,
      client: client
    }
  end

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

  let(:data) { { type: 'example', name: 'Test data example' } }

  include_context 'with mocked objects for Elasticsearch::Indexable'

  describe '#initialize' do
    subject(:method_call) { index }

    it_behaves_like 'Indexable#initialize'
  end

  describe '#push' do
    subject(:method_call) { described_method.call }

    let(:method_params) { {} }

    # Needed in order to be able to repeat the method call
    let(:described_method) { -> { index.push(data, **method_params) } }

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

    shared_examples_for '#push' do
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

    context 'when no type is specified' do
      let(:method_params) { {} }

      it_behaves_like '#push'
    end

    context "when 'nested' is specified as a type" do
      let(:method_params) { { type: 'nested' } }

      it_behaves_like '#push'
    end

    context 'when nil is specified as a type' do
      let(:method_params) { { type: nil } }

      let(:expected_data) do
        {
          body: [
            {
              index: {
                _index: index_name,
                # _type: 'nested', <==== Removed, it should not be present
                data: data
              }
            }
          ] * 10
        }
      end

      it_behaves_like '#push'
    end

    it_behaves_like 'Indexable#validate_type'
  end

  describe '#index' do
    subject(:method_call) { index.index(data, **method_params) }

    let(:method_params) { {} }

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

    it_behaves_like 'Indexable#validate_type'
  end

  describe '#settings' do
    subject(:method_call) { index.settings }

    let(:settings) do
      instance_double(
        JayAPI::Elasticsearch::Indices::Settings
      )
    end

    before do
      allow(JayAPI::Elasticsearch::Indices::Settings)
        .to receive(:new).and_return(settings)
    end

    it 'creates an instance of the Settings class with the expected parameters' do
      expect(JayAPI::Elasticsearch::Indices::Settings)
        .to receive(:new).with(transport_client, 'elite_unit_tests')

      method_call
    end

    it 'returns the Settings object' do
      expect(method_call).to be(settings)
    end
  end

  describe '#queue_size' do
    subject(:method_call) { index.queue_size }

    let(:constructor_params) do
      super().merge(batch_size: 15)
    end

    let(:indexable) { index }

    it_behaves_like 'Indexable#queue_size'

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

  describe '#flush' do
    subject(:method_call) { index.flush }

    let(:indexable) { index }

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

    it_behaves_like 'Indexable#flush'
  end

  describe '#search' do
    subject(:method_call) { index.search(query, **method_params) }

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

    let(:indexable) { index }

    let(:expected_query) do
      {
        index: [index_name],
        body: query
      }
    end

    it_behaves_like 'Indexable#search'
  end

  describe '#delete_by_query' do
    subject(:method_call) { index.delete_by_query(query, **method_params) }

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

    let(:index_names) { [index_name] }

    it_behaves_like 'Indexable#delete_by_query'
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

    let(:indexable) { index }

    it_behaves_like 'Indexable#delete_by_query_async'
  end
end
