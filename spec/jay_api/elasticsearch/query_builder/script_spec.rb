# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/script'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Script do
  subject(:script) { described_class.new(**constructor_params) }

  let(:source) do
    <<~PAINLESS
      return Math.min(100, doc['grade'].value * 1.2)
    PAINLESS
  end

  let(:constructor_params) do
    { source: source }
  end

  describe '#initialize' do
    subject(:method_call) { script }

    context 'when no `params` are given' do
      it 'does not raise any errors' do
        expect { method_call }.not_to raise_error
      end
    end

    context 'when `params` is set to `nil`' do
      let(:constructor_params) { { source: source, params: nil } }

      it 'does not raise any errors' do
        expect { method_call }.not_to raise_error
      end
    end

    context 'when params are given' do
      let(:params) { { correction: 1.2 } }
      let(:constructor_params) { { source: source, params: params } }

      it "exposes the given parameters via the 'params' attribute" do
        expect(script.params).to eq(params)
      end

      it 'dups the given parameters instead of assigning them directly' do
        expect(script.params).not_to be(params)
      end

      it 'freezes the dupped parameters' do
        expect(script.params).to be_frozen
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { script.to_h }

    context 'when no language was given to the constructor' do
      let(:expected_hash) do
        {
          source: <<~PAINLESS,
            return Math.min(100, doc['grade'].value * 1.2)
          PAINLESS
          lang: 'painless'
        }
      end

      it 'returns the expected Hash (uses painless as the default language)' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when a language is given' do
      let(:source) do
        <<~PYTHON
          return min(100, doc['grade'].value * 1.2)
        PYTHON
      end

      let(:constructor_params) do
        { source: source, lang: 'python' }
      end

      let(:expected_hash) do
        {
          source: <<~PYTHON,
            return min(100, doc['grade'].value * 1.2)
          PYTHON
          lang: 'python'
        }
      end

      it 'returns the expected hash (uses the specified language)' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when no `params` are given to the constructor' do
      it 'does not include the `params` key' do
        expect(method_call).not_to have_key(:params)
      end
    end

    context 'when `nil` is given as `params` to the constructor' do
      let(:constructor_params) { { source: source, params: nil } }

      it 'does not include the `params` key' do
        expect(method_call).not_to have_key(:params)
      end
    end

    context 'when params are given to the constructor' do
      let(:source) do
        <<~PAINLESS
          return Math.min(100, doc['grade'].value * params.correction)
        PAINLESS
      end

      let(:constructor_params) do
        { source: source, params: { correction: 1.2 } }
      end

      let(:expected_hash) do
        {
          source: <<~PAINLESS,
            return Math.min(100, doc['grade'].value * params.correction)
          PAINLESS
          lang: 'painless',
          params: { correction: 1.2 }
        }
      end

      it 'returns the expected Hash (including the `params` Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
