# frozen_string_literal: true

require 'jay_api/elasticsearch/query_results'

require_relative '../index'

RSpec.shared_context 'with a query that returns results' do
  let(:query) do
    {
      'query' => {
        'match_all' => {}
      }
    }
  end
end

RSpec.shared_context 'with a query that does not return results' do
  let(:query) do
    {
      'query' => {
        'match' => {
          'id' => -1 # <-- purposely some query that should return no docs
        }
      }
    }
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryResults#size' do
  context 'when there are documents in the results' do
    include_context 'with a query that returns results'

    it 'returns the number of documents in the results' do
      expect(method_call).to eq(6)
    end
  end

  context 'when there are no documents in the results' do
    include_context 'with a query that does not return results'

    it 'returns 0' do
      expect(method_call).to eq(0)
    end
  end
end

RSpec.describe JayAPI::Elasticsearch::QueryResults do
  subject(:query_results) { index.search(query) }

  include_context 'with JayAPI::Elasticsearch::Index'

  let(:index_name) { 'query_results_spec_initialize' }
  let(:docs_to_upload) { [{ id: 1 }, { id: 3 }, { id: 5 }, { id: 7 }, { id: 9 }, { id: 11 }] }

  before do
    unless client.transport_client.indices.exists(index: index_name)
      docs_to_upload.each { |doc| index.push(doc) }
      index.flush
      sleep 2 # For Elasticsearch to process the data
    end
  end

  describe '#initialize' do
    context 'when the query has a size' do
      let(:query) do
        {
          'query' => {
            'match_all' => {}
          },
          'size' => 11 # <--- the relevant attribute
        }
      end

      it 'takes the batch size from the query' do
        expect(query_results.batch_size).to eq(11)
      end
    end

    context 'when the query has no size' do
      let(:query) do
        {
          'query' => {
            'match_all' => {}
          }
          # 'size' => 11 # <--- no 'size' attribute present
        }
      end

      it 'takes the batch size from the results' do
        expect(query_results.batch_size).to eq(6)
      end
    end

    context 'when there are no documents in the results' do
      include_context 'with a query that does not return results'

      it 'sets the start of the next batch at 0' do
        expect(query_results.start_next).to eq(0)
      end
    end

    context 'when there are documents in the results' do
      include_context 'with a query that returns results'

      it 'sets the start of the next batch to the size of the results' do
        expect(query_results.start_next).to eq(6)
      end
    end
  end

  describe '#total' do
    subject(:method_call) { query_results.total }

    context 'when the results have a total' do
      include_context 'with a query that returns results'

      it 'returns the value from the results' do
        expect(method_call).to eq(6)
      end
    end

    context 'when the results have to no total' do
      # An invalid query to trigger an error from Elasticsearch, which is a scenario
      # in which the result json does not contain the "'hits' -> 'total' -> 'value'".
      let(:query) do
        {
          'query' => {
            'match' => {
              'nonexistent_field' => 'value'
            }
          }
        }
      end

      it 'returns 0' do
        expect(method_call).to eq(0)
      end
    end
  end

  describe '#size' do
    subject(:method_call) { query_results.size }

    it_behaves_like 'JayAPI::Elasticsearch::QueryResults#size'
  end

  describe '#count' do
    subject(:method_call) { query_results.count }

    it_behaves_like 'JayAPI::Elasticsearch::QueryResults#size'
  end

  describe '#first' do
    subject(:method_call) { query_results.first }

    context 'when there are no documents' do
      include_context 'with a query that does not return results'

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end

    context 'when there are documents' do
      include_context 'with a query that returns results'

      it 'returns the first document' do
        expect(method_call).to match(including('_source' => { 'id' => 1 }))
      end
    end
  end

  describe '#last' do
    subject(:method_call) { query_results.last }

    context 'when there are no documents' do
      include_context 'with a query that does not return results'

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end

    context 'when there are documents' do
      include_context 'with a query that returns results'

      it 'returns the last document' do
        expect(method_call['_source']).to eq({ 'id' => 11 })
      end
    end
  end

  describe '#empty?' do
    subject(:method_call) { query_results.empty? }

    context 'when there are no documents' do
      include_context 'with a query that does not return results'

      it 'returns true' do
        expect(method_call).to be(true)
      end
    end

    context 'when there are documents' do
      include_context 'with a query that returns results'

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end
  end

  describe '#any?' do
    subject(:method_call) { query_results.any? }

    context 'when there are no documents' do
      include_context 'with a query that does not return results'

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end

    context 'when there are documents' do
      include_context 'with a query that returns results'

      it 'returns true' do
        expect(method_call).to be(true)
      end
    end
  end

  describe '#more?' do
    subject(:method_call) { query_results.more? }

    context 'when there are no documents' do
      include_context 'with a query that does not return results'

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end

    context 'when there are less documents than the total' do
      let(:query) do
        {
          'query' => {
            'match_all' => {}
          },
          'size' => 3 # only fetch 3 in the first batch, so there ares still more to fetch
        }
      end

      it 'returns true' do
        expect(method_call).to be(true)
      end
    end

    context 'when there are as many documents as the total' do
      include_context 'with a query that returns results'

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end
  end

  describe '#each' do
    include_context 'with a query that returns results'

    context 'without a block' do
      it 'returns an Enumerator' do
        expect(query_results.each).to be_a(Enumerator)
      end
    end

    context 'with a block' do
      it 'yields each document to the block' do
        expect { |b| query_results.each(&b) }
          .to yield_control.exactly(docs_to_upload.size).times
      end
    end
  end

  describe '#all' do
    context 'when there is only one batch of documents' do
      include_context 'with a query that returns results'

      it 'yields each document to the block' do
        expect { |b| query_results.all(&b) }
          .to yield_control.exactly(docs_to_upload.size).times
      end

      it 'returns itself' do
        result = query_results.all { nil }
        expect(result).to eq(query_results)
      end

      context 'when no block is given' do
        it 'returns an Enumerator' do
          expect(query_results.all).to be_a(Enumerator)
        end

        it 'sets the proper size for the Enumerator' do
          expect(query_results.all.size).to eq(docs_to_upload.size)
        end
      end
    end

    context 'when there is more than one batch of documents' do
      let(:query) do
        {
          'query' => {
            'match_all' => {}
          },
          'size' => 4 # this splits the docs of size 6 into two batches: first with 4 and second with 2
        }
      end

      it 'yields all documents to the block' do
        expect { |b| query_results.all(&b) }.to yield_successive_args(
          including('_source' => { 'id' => 1 }),
          including('_source' => { 'id' => 3 }),
          including('_source' => { 'id' => 5 }),
          including('_source' => { 'id' => 7 }),
          including('_source' => { 'id' => 9 }),
          including('_source' => { 'id' => 11 })
        )
      end

      it 'returns the last batch of documents' do
        result = query_results.all { nil }
        expect { |b| result.all(&b) }.to yield_successive_args(
          # since query was with size 4, only two documents will remain in the second/last batch
          including('_source' => { 'id' => 9 }),
          including('_source' => { 'id' => 11 })
        )
      end

      context 'when no block is given' do
        it 'returns an Enumerator' do
          expect(query_results.all).to be_an(Enumerator)
        end

        it 'sets the proper size for the Enumerator' do
          expect(query_results.all.size).to eq(6)
        end

        context 'when called on the second batch' do
          it 'sets the proper size for the Enumerator' do
            second_batch = query_results.next_batch
            expect(second_batch.all.size).to eq(2)
          end
        end
      end
    end
  end
end
