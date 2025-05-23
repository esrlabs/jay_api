# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/node/storage'

RSpec.describe JayAPI::Elasticsearch::Stats::Node::Storage do
  subject(:storage) { described_class.new(data) }

  let(:data) do
    {
      'total_in_bytes' => 5_126_127_616,
      'free_in_bytes' => 4_576_702_464,
      'available_in_bytes' => 4_559_925_248
    }
  end

  describe '#total' do
    subject(:method_call) { storage.total }

    it 'returns the total number of bytes' do
      expect(method_call).to eq(5_126_127_616)
    end
  end

  describe '#free' do
    subject(:method_call) { storage.free }

    it 'returns the total number of free bytes' do
      expect(method_call).to eq(4_576_702_464)
    end
  end

  describe '#available' do
    subject(:method_call) { storage.available }

    it 'returns the total number of available bytes' do
      expect(method_call).to eq(4_559_925_248)
    end
  end

  describe '#+' do
    subject(:method_call) { storage + other }

    let(:other) do
      described_class.new(
        'total_in_bytes' => 316_863_741_952,
        'free_in_bytes' => 25_923_690_496,
        'available_in_bytes' => 25_906_913_280
      )
    end

    context "when 'other' is not an instance of #{described_class}" do
      let(:other) do
        {
          'total_in_bytes' => 316_863_741_952,
          'free_in_bytes' => 25_923_690_496,
          'available_in_bytes' => 25_906_913_280
        }
      end

      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(
          ArgumentError,
          'Cannot add JayAPI::Elasticsearch::Stats::Node::Storage and Hash together'
        )
      end
    end

    it 'does not return the receiver nor other' do
      expect(method_call).not_to be(storage)
      expect(method_call).not_to be(other)
      method_call
    end

    it "returns a new instance of #{described_class}" do
      expect(method_call).to be_a(described_class)
    end

    it "returns an instance of #{described_class} with the expected number of total bytes" do
      expect(method_call.total).to eq(321_989_869_568)
    end

    it "returns an instance of #{described_class} with the expected number of free bytes" do
      expect(method_call.free).to eq(30_500_392_960)
    end

    it "returns an instance of #{described_class} with the expected number of available bytes" do
      expect(method_call.available).to eq(30_466_838_528)
    end
  end
end
