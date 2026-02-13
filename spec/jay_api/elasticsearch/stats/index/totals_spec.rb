# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/index/totals'

RSpec.describe JayAPI::Elasticsearch::Stats::Index::Totals do
  subject(:totals) { described_class.new(data) }

  let(:docs) do
    { 'count' => 530_626, 'deleted' => 11 }
  end

  let(:data) do
    {
      'docs' => docs,
      'store' => { 'size_in_bytes' => 1_001_425_875, 'reserved_in_bytes' => 0 },
      'flush' => { 'total' => 25, 'periodic' => 0, 'total_time_in_millis' => 1924 },
      'warmer' => { 'current' => 0, 'total' => 30, 'total_time_in_millis' => 0 },
      'completion' => { 'size_in_bytes' => 0 }
    }
  end

  shared_examples_for '#docs' do
    context "when the data doesn't have a 'docs' key" do
      let(:data) { super().except('docs') }

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "docs"'
        )
      end
    end
  end

  shared_examples_for '#docs_count' do
    it_behaves_like '#docs'

    context "when the data doesn't contain the total number of documents" do
      let(:docs) { super().except('count') }

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "count"'
        )
      end
    end
  end

  describe '#docs_count' do
    subject(:method_call) { totals.docs_count }

    it_behaves_like '#docs_count'

    it 'returns the expected number of documents' do
      expect(method_call).to eq(530_626)
    end
  end

  shared_examples_for '#deleted_docs' do
    it_behaves_like '#docs'

    context "when the data doesn't contain the number of deleted documents" do
      let(:docs) { super().except('deleted') }

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "deleted"'
        )
      end
    end
  end

  describe '#deleted_docs' do
    subject(:method_call) { totals.deleted_docs }

    it_behaves_like '#deleted_docs'

    it 'returns the expected number of deleted documents' do
      expect(method_call).to eq(11)
    end
  end

  describe '#deleted_ratio' do
    subject(:method_call) { totals.deleted_ratio }

    it_behaves_like '#docs_count'
    it_behaves_like '#deleted_docs'

    context 'when the index has no documents' do
      let(:docs) { super().merge('count' => 0) }

      context 'when the index has no deleted documents' do
        let(:docs) { super().merge('deleted' => 0) }

        it 'returns 0' do
          expect(method_call).to be_zero
        end
      end

      context 'when the index has deleted documents' do
        it 'returns 1' do
          expect(method_call).to be(1.0)
        end
      end
    end

    context 'when the index has documents' do
      context 'when the index has no deleted documents' do
        let(:docs) { super().merge('deleted' => 0) }

        it 'returns 0' do
          expect(method_call).to be_zero
        end
      end

      context 'when the index has deleted documents' do
        let(:docs) { super().merge('deleted' => 10_636) }

        it 'returns the expected ratio' do
          expect(method_call).to be_within(0.0001).of(0.02)
        end
      end
    end
  end
end
