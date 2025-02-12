# frozen_string_literal: true

require 'jay_api/elasticsearch/response'

RSpec.describe JayAPI::Elasticsearch::Response do
  subject(:response) { described_class.new(sample_results) }

  let(:sample_results) do
    {
      'hits' => {
        'hits' => [
          { '_id' => 1, '_source' => { 'data' => 'one' } },
          { '_id' => 2, '_source' => { 'data' => 'two' } },
          { '_id' => 3, '_source' => { 'data' => 'three' } },
          { '_id' => 4, '_source' => { 'data' => 'four' } }
        ],
        'total' => { 'value' => 10 }
      }
    }
  end

  describe '#aggregations' do
    subject(:method_call) { response.aggregations }

    context 'when there are no aggregations' do
      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end

    context 'when there are aggregations' do
      let(:aggregations) do
        {
          'runtime' => {
            'value' => 10.24
          }
        }
      end

      before do
        sample_results.merge!(
          {
            'aggregations' => aggregations
          }
        )
      end

      it 'returns the aggregations hash' do
        expect(method_call).to eq(aggregations)
      end
    end
  end

  describe '#hits' do
    subject(:method_call) { response.hits }

    context 'when hits are absent' do
      let(:sample_results) { {} }

      it 'defaults hits to an empty array' do
        expect(method_call).to eq([])
      end
    end

    context 'when there are hits' do
      let(:expected_hits) do
        [
          { '_id' => 1, '_source' => { 'data' => 'one' } },
          { '_id' => 2, '_source' => { 'data' => 'two' } },
          { '_id' => 3, '_source' => { 'data' => 'three' } },
          { '_id' => 4, '_source' => { 'data' => 'four' } }
        ]
      end

      it 'returns the hits' do
        expect(method_call).to eq(expected_hits)
      end
    end
  end

  describe '#total' do
    subject(:method_call) { response.total }

    context 'when the total size is specified in the returned Elasticsearch response' do
      it 'returns the total number taken from the response' do
        expect(method_call).to eq(10)
      end
    end

    context 'when the total size is not specified in the returned Elasticsearch response' do
      before do
        sample_results['hits'].delete('total')
      end

      it 'returns the size of the actual hits array' do
        expect(method_call).to eq(4)
      end
    end
  end

  describe 'delegated methods' do
    describe '#size' do
      it 'returns the size of hits' do
        expect(response.size).to eq(4)
      end
    end

    describe '#count' do
      it 'returns the count of hits' do
        expect(response.count).to eq(4)
      end
    end

    describe '#first' do
      it 'returns the first hit' do
        expect(response.first).to eq({ '_id' => 1, '_source' => { 'data' => 'one' } })
      end
    end

    describe '#last' do
      it 'returns the last hit' do
        expect(response.last).to eq({ '_id' => 4, '_source' => { 'data' => 'four' } })
      end
    end

    describe '#any?' do
      context 'when there are some hits' do
        it 'returns true' do
          expect(response.any?).to be(true)
        end
      end

      context 'when hits are empty' do
        before do
          sample_results['hits']['hits'] = []
        end

        it 'returns false' do
          expect(response.any?).to be(false)
        end
      end
    end

    describe '#empty?' do
      context 'when there are some hits' do
        it 'returns false' do
          expect(response.empty?).to be(false)
        end
      end

      context 'when hits are empty' do
        before do
          sample_results['hits']['hits'] = []
        end

        it 'returns true' do
          expect(response.empty?).to be(true)
        end
      end
    end
  end
end
