# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/range'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range do
  subject(:range) { described_class.new(params) }

  let(:field) { { field: 'age' } }

  let(:params) do
    field.merge(
      gte: 10,
      lte: 20
    )
  end

  describe '#initialize' do
    subject(:method_call) { range }

    shared_examples 'raises an ArgumentError' do
      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(
          ArgumentError, message
        )
      end
    end

    context 'when the :field key is missing' do
      let(:params) { { lte: 18 } }
      let(:message) { "Missing required key 'field'" }

      include_examples 'raises an ArgumentError'
    end

    context 'when invalid keys are used' do
      let(:params) { field.merge(gte: 10, max: 100, jitter: 0.05) }
      let(:message) { 'Invalid keys: max, jitter' }

      include_examples 'raises an ArgumentError'
    end

    context 'when none of the valid keys are passed' do
      let(:params) { field }
      let(:message) { 'At least one of gt, gte, lt, lte should be given' }

      include_examples 'raises an ArgumentError'
    end

    context 'when valid keys are passed with nil values' do
      let(:params) { field.merge(lt: nil, gte: nil) }
      let(:message) { 'At least one of gt, gte, lt, lte should be given' }

      include_examples 'raises an ArgumentError'
    end

    context 'with valid parameters' do
      it 'raises no error' do
        expect { method_call }.not_to raise_error
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { range.to_h }

    let(:expected_hash) do
      {
        range: {
          'age' => {
            gte: 10,
            lte: 20
          }
        }
      }
    end

    shared_examples 'returns the expected hash' do
      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when params are passed with nil values' do
      let(:params) { field.merge(lt: nil, lte: 20, gte: 10, gt: nil) }

      include_examples 'returns the expected hash'
    end

    include_examples 'returns the expected hash'
  end
end
