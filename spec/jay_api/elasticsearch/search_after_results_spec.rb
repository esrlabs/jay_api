# frozen_string_literal: true

require 'jay_api/elasticsearch/search_after_results'

require_relative 'query_results'

RSpec.describe JayAPI::Elasticsearch::SearchAfterResults do
  subject(:query_results) do
    described_class.new(
      index: index,
      query: query,
      response: response,
      batch_counter: batch_counter
    )
  end

  include_context 'with QueryResults'

  it_behaves_like 'QueryResults#each'
  it_behaves_like 'QueryResults#aggregations'

  describe '#more?' do
    context 'when there are no more documents' do
      let(:total) { 4 }
      let(:start_next) { 6 }

      it 'returns true' do
        expect(query_results.more?).to be(true)
      end
    end

    context 'when there are less documents than the total' do
      let(:total) { 4 }
      let(:batch_start) { 2 }

      it 'returns true' do
        expect(query_results.more?).to be(true)
      end
    end

    context 'when the batch_start is the same as the total' do
      let(:total) { 4 }
      let(:batch_start) { 4 }

      it 'returns true' do
        expect(query_results.more?).to be(true)
      end
    end
  end

  shared_context 'with SearchAfterResults that has more documents to fetch' do
    include_context 'with QueryResults that has more documents to fetch'

    let(:next_query) do
      query.merge('size' => 2, 'from' => -1, 'search_after' => [1234])
    end

    before do
      allow(index).to receive(:search)
        .with(next_query, batch_counter: batch_counter, type: :search_after).and_return(next_query_results)
    end
  end

  describe '#all' do
    context 'when there is only one batch of documents' do
      let(:any) { false }

      it_behaves_like 'QueryResults#all when there is only one batch of documents'
    end

    context 'when there is more than one batch of documents' do
      include_context 'with SearchAfterResults that has more documents to fetch'

      it_behaves_like 'QueryResults#all when there is more than one batch of documents'

      it 'fetches the next batch with the :search_after parameter' do
        expect(index).to receive(:search).with(next_query, batch_counter: batch_counter, type: :search_after)
        # rubocop: disable Lint/EmptyBlock
        query_results.all {}
        # rubocop: enable Lint/EmptyBlock
      end
    end
  end

  describe '#next_batch' do
    subject(:next_batch) { query_results.next_batch }

    context 'when there are more documents to fetch' do
      include_context 'with SearchAfterResults that has more documents to fetch'

      it 'performs the expected query (with adapted from and size params)' do
        expect(index).to receive(:search)
          .with(next_query, batch_counter: batch_counter, type: :search_after)

        next_batch
      end

      it 'returns the next QueryResults object' do
        expect(next_batch).to eq(next_query_results)
      end
    end
  end
end
