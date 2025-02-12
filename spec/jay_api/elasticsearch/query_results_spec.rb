# frozen_string_literal: true

require 'jay_api/elasticsearch/query_results'

require_relative 'query_results'

RSpec.describe JayAPI::Elasticsearch::QueryResults do
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

      it 'returns false' do
        expect(query_results.more?).to be(false)
      end
    end

    context 'when there are less documents than the total' do
      let(:total) { 4 }
      let(:start_next) { 2 }

      it 'returns true' do
        expect(query_results.more?).to be(true)
      end
    end

    context 'when the start_next is the same as the total' do
      let(:total) { 4 }
      let(:start_next) { 4 }

      it 'returns false' do
        expect(query_results.more?).to be(false)
      end
    end
  end

  describe '#all' do
    context 'when there is only one batch of documents' do
      it_behaves_like 'QueryResults#all when there is only one batch of documents'
    end

    context 'when there is more than one batch of documents' do
      include_context 'with QueryResults that has more documents to fetch'

      it_behaves_like 'QueryResults#all when there is more than one batch of documents'

      it 'fetches the next batch after reaching the end of the first one' do
        expect(index).to receive(:search).with(next_query, batch_counter: batch_counter)
        # rubocop: disable Lint/EmptyBlock Some blocks must be empty because the tests only test whether a block is yielded
        query_results.all {}
        # rubocop: enable Lint/EmptyBlock
      end
    end
  end

  describe '#next_batch' do
    subject(:next_batch) { query_results.next_batch }

    context 'when there are no documents' do
      let(:total) { 4 }
      let(:start_next) { 6 }

      it 'raises an EndOfQueryResultsError' do
        expect { next_batch }
          .to raise_error(JayAPI::Elasticsearch::Errors::EndOfQueryResultsError)
      end
    end

    context 'when there are documents' do
      context 'when the end of the query results has been reached' do
        let(:total) { 4 }
        let(:start_next) { 6 }

        it 'raises an EndOfQueryResultsError' do
          expect { next_batch }
            .to raise_error(JayAPI::Elasticsearch::Errors::EndOfQueryResultsError)
        end
      end
    end

    context 'when there are more documents to fetch' do
      include_context 'with QueryResults that has more documents to fetch'

      it 'performs the expected query (with adapted from and size params)' do
        expect(index).to receive(:search)
          .with(next_query, batch_counter: batch_counter)

        next_batch
      end

      it 'returns the next QueryResults object' do
        expect(next_batch).to eq(next_query_results)
      end
    end
  end
end
