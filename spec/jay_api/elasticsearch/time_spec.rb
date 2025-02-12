# frozen_string_literal: true

require 'jay_api/elasticsearch/time'

RSpec.describe JayAPI::Elasticsearch::Time do
  let(:described_class) do
    Class.new do
      include JayAPI::Elasticsearch::Time
    end.new
  end

  describe '#format_time' do
    let(:time) { Time.new(2012, 12, 12, 14, 12, 12, '+02:00') }
    let(:expected_string) { '2012/12/12 12:12:12' }

    it 'formats time properly' do
      expect(described_class.format_time(time)).to eq(expected_string)
    end
  end
end
