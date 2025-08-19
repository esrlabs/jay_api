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

    # Needed in order to be able to repeat the method call
    let(:described_method) { -> { index.push(data) } }

    it_behaves_like 'Indexable#push'
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

    it_behaves_like 'Indexable#index'
  end

  describe '#queue_size' do
    subject(:method_call) { index.queue_size }

    let(:indexable) { index }

    it_behaves_like 'Indexable#queue_size'
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
