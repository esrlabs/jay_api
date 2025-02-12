# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/regexp'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp do
  subject(:regexp) do
    described_class.new(
      field: 'sut_revision.keyword',
      value: '[0-9]{2}-[0-9]{2}-[0-9]{2}/.*'
    )
  end

  describe '#initialize' do
    subject(:method_call) { regexp }

    it 'sets the field to the passed one' do
      expect(method_call.field).to eq('sut_revision.keyword')
    end

    it 'sets the value to the passed one' do
      expect(method_call.value).to eq('[0-9]{2}-[0-9]{2}-[0-9]{2}/.*')
    end
  end

  describe '#to_h' do
    subject(:method_call) { regexp.to_h }

    let(:expected_hash) do
      {
        regexp: {
          'sut_revision.keyword' => {
            value: '[0-9]{2}-[0-9]{2}-[0-9]{2}/.*'
          }
        }
      }
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end
  end
end
