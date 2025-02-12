# frozen_string_literal: true

require 'jay_api/elasticsearch/response'
require 'jay_api/elasticsearch/batch_counter'

RSpec.shared_context 'with QueryResults' do
  let(:index) { instance_double(JayAPI::Elasticsearch::Index) }
  let(:query) { { 'some' => 'query' } }
  let(:raw_results) { { 'hits' => { 'hits' => hits, 'total' => { 'value' => 4 } } } }

  let(:response) do
    instance_double(JayAPI::Elasticsearch::Response, hits: hits, total: total, any?: any, last: hits.last)
  end
  let(:hits) do
    [
      { 'some' => 'document' },
      { 'second' => 'document?' },
      { 'what' => 'document!' },
      { 'this' => 'not document' },
      { 'another' => 'document', 'sort' => [1234] }
    ]
  end
  let(:total) { 4 }
  let(:any) { true }

  let(:batch_counter) do
    instance_double(
      JayAPI::Elasticsearch::BatchCounter,
      batch_size: batch_size,
      start_current: start_current,
      size: size,
      start_next: start_next
    )
  end
  let(:batch_size) { 2 }
  let(:start_current) { 0 }
  let(:size) { 2 }
  let(:start_next) { 2 }
end

RSpec.shared_context 'with QueryResults that has more documents to fetch' do
  let(:next_hits) do
    [
      { 'next' => 'document' },
      { 'i am' => 'hiding here' },
      { 'another_next' => 'document', 'sort' => [4321] }
    ]
  end
  let(:next_response) do
    instance_double(JayAPI::Elasticsearch::Response, hits: next_hits, total: 4, last: next_hits.last, any?: false)
  end
  let(:next_batch_counter) do
    instance_double(
      JayAPI::Elasticsearch::BatchCounter,
      batch_size: 2,
      start_current: 2,
      size: 2,
      start_next: 4
    )
  end
  let(:next_query) do
    query.merge('size' => 2, 'from' => 2)
  end
  let(:next_query_results) do
    described_class.new(index: index, query: next_query, response: next_response, batch_counter: next_batch_counter)
  end

  before do
    allow(index).to receive(:search)
      .with(next_query, batch_counter: batch_counter).and_return(next_query_results)
  end
end

RSpec.shared_examples_for 'QueryResults#each' do
  context 'without a block' do
    it 'returns an Enumerator' do
      expect(query_results.each).to be_a(Enumerator)
    end
  end

  context 'with a block' do
    it 'yields each document to the block' do
      expect { |b| query_results.each(&b) }
        .to yield_successive_args(*hits)
    end

    it 'does not trigger a new search' do
      expect(index).not_to receive(:search)
      # rubocop: disable Lint/EmptyBlock
      query_results.each {}
      # rubocop: enable Lint/EmptyBlock
    end
  end
end

RSpec.shared_examples_for 'QueryResults#all when there is only one batch of documents' do
  let(:total) { 4 }
  let(:start_next) { 6 }

  it 'yields each document to the block' do
    expect { |b| query_results.all(&b) }.to yield_successive_args(*hits)
  end

  it 'does not trigger a new search' do
    expect(index).not_to receive(:search)
    # rubocop: disable Lint/EmptyBlock
    query_results.all {}
    # rubocop: enable Lint/EmptyBlock
  end

  it 'returns itself' do
    # rubocop: disable Lint/EmptyBlock
    result = query_results.all {}
    # rubocop: enable Lint/EmptyBlock
    expect(result).to eq(query_results)
  end

  context 'when no block is given' do
    it 'returns an Enumerator' do
      expect(query_results.all).to be_a(Enumerator)
    end

    it 'sets the proper size for the Enumerator' do
      expect(query_results.all.size).to eq(total)
    end
  end
end

RSpec.shared_examples_for 'QueryResults#all when there is more than one batch of documents' do
  it 'yields each document to the block' do
    expect { |b| query_results.all(&b) }.to yield_successive_args(*hits, *next_hits)
  end

  it 'calls each on the second batch of documents' do
    expect(next_query_results).to receive(:each)
    # rubocop: disable Lint/EmptyBlock
    query_results.all {}
    # rubocop: enable Lint/EmptyBlock
  end

  it 'returns the last batch of documents' do
    # rubocop: disable Lint/EmptyBlock
    result = query_results.all {}
    # rubocop: enable Lint/EmptyBlock
    expect(result).to eq(next_query_results)
  end

  context 'when no block is given' do
    it 'returns an Enumerator' do
      expect(query_results.all).to be_a(Enumerator)
    end

    it 'sets the proper size for the Enumerator' do
      expect(query_results.all.size).to eq(total)
    end

    context 'when called on the second batch' do
      it 'sets the proper size for the Enumerator' do
        second_batch = query_results.next_batch
        expect(second_batch.all.size).to eq(2)
      end
    end
  end
end

RSpec.shared_examples_for 'QueryResults#aggregations' do
  subject(:method_call) { query_results.aggregations }

  let(:val_from_response) do
    {
      'my-agg-name' => {
        'doc_count_error_upper_bound' => 0,
        'sum_other_doc_count' => 0,
        'buckets' => []
      }
    }
  end

  before do
    allow(response).to receive(:aggregations).and_return(val_from_response)
  end

  it 'returns the value from the Results object' do
    expect(method_call).to be(val_from_response)
  end
end
