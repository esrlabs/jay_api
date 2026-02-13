# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/index'

RSpec.describe JayAPI::Elasticsearch::Stats::Index do
  subject(:index) { described_class.new(name, data) }

  let(:name) { 'xyz01_integration_tests' }

  let(:data) do
    {
      'uuid' => 'rouPqkZMSrKHY5bzL7OhTA',
      'primaries' => {
        'docs' => { 'count' => 265_313, 'deleted' => 0 },
        'store' => { 'size_in_bytes' => 497_335_237, 'reserved_in_bytes' => 0 }
      },
      'total' => {
        'docs' => { 'count' => 530_626, 'deleted' => 11 },
        'store' => { 'size_in_bytes' => 1_001_425_875, 'reserved_in_bytes' => 0 }
      }
    }
  end

  describe '#initialize' do
    subject(:method_call) { index }

    it 'stores the given name' do
      method_call
      expect(index.name).to be(name)
    end
  end

  describe '#totals' do
    subject(:method_call) { index.totals }

    let(:totals_hash) do
      {
        'docs' => { 'count' => 530_626, 'deleted' => 11 },
        'store' => { 'size_in_bytes' => 1_001_425_875, 'reserved_in_bytes' => 0 }
      }
    end

    let(:totals) do
      instance_double(
        JayAPI::Elasticsearch::Stats::Index::Totals
      )
    end

    before do
      allow(JayAPI::Elasticsearch::Stats::Index::Totals)
        .to receive(:new).and_return(totals)
    end

    context "when the index's data doesn't contain the totals information" do
      let(:data) { super().except('total') }

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "total"'
        )
      end
    end

    it 'creates a new instance of the Totals class with the expected Hash' do
      expect(JayAPI::Elasticsearch::Stats::Index::Totals).to receive(:new).with(totals_hash)
      method_call
    end

    it 'returns the instance of the Totals class' do
      expect(method_call).to be(totals)
    end
  end
end
