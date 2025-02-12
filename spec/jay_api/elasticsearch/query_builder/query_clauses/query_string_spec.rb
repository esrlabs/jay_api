# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/query_string'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString do
  subject(:query_string) { described_class.new(**params) }

  let(:query) { '(new york city) OR (big apple)' }
  let(:params) { { query: query } }

  shared_context 'with fields' do
    before { params.merge!(fields: fields) }
  end

  shared_context 'with a single field' do
    let(:fields) { 'content' }
  end

  shared_context 'with multiple fields' do
    let(:fields) { %w[content name] }
  end

  describe '#initialize' do
    context "when the 'fields' parameter is not present" do
      it 'leaves it as nil' do
        expect(query_string.fields).to be_nil
      end
    end

    context "when the 'fields' parameter is present" do
      include_context 'with fields'

      context "when the 'fields' parameter is not an array" do
        include_context 'with a single field'

        it 'turns it into an array' do
          expect(query_string.fields).to eq(['content'])
        end
      end

      context 'when the fields parameter is already an array' do
        include_context 'with multiple fields'

        it 'leaves it unchanged' do
          expect(query_string.fields).to eq(%w[content name])
        end
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { query_string.to_h }

    shared_examples 'returns the expected Hash' do
      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when the 'fields' parameter is not present" do
      let(:expected_hash) do
        {
          query_string: {
            query: '(new york city) OR (big apple)'
          }
        }
      end

      include_examples 'returns the expected Hash'
    end

    context "when the 'fields' parameter is present" do
      include_context 'with fields'

      context "when the 'fields' parameter is not an array" do
        include_context 'with a single field'

        let(:expected_hash) do
          {
            query_string: {
              query: '(new york city) OR (big apple)',
              fields: ['content']
            }
          }
        end

        include_examples 'returns the expected Hash'
      end

      context "when the 'fields' parameter is an array" do
        include_context 'with multiple fields'

        let(:expected_hash) do
          {
            query_string: {
              query: '(new york city) OR (big apple)',
              fields: %w[content name]
            }
          }
        end

        include_examples 'returns the expected Hash'
      end
    end
  end
end
