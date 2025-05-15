# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/indices'

RSpec.describe JayAPI::Elasticsearch::Stats::Indices do
  subject(:indices) { described_class.new(indices_hash) }

  let(:indices_hash) do
    {
      'xyz01_integration_test' => {
        'uuid' => 'OXRb8_IYTseG2epNa9Ls3g'
      },
      'xyz01_unit_tests' => {
        'uuid' => 'hxDdhi-3TFSndxhLesspFw'
      },
      '.kibana_views' => {
        'uuid' => 'pr-VjrPARlG3lAoAfPqNog'
      },
      'xyz02_manual_verification' => {
        'uuid' => 'uaZ_kKQuSM-HaKH_LcI7BQ'
      },
      '.backup' => {
        'uuid' => 'N7TZOstjRHu8mTwsLZuQ5w'
      }
    }
  end

  shared_examples_for '#all' do
    it 'returns an Enumerator::Lazy' do
      expect(method_call).to be_a(Enumerator::Lazy)
    end

    it 'includes the expected number of indices' do
      expect(method_call.size).to eq(expected_indices_size)
    end

    it 'includes only instances of JayAPI::Elasticsearch::Stats::Index' do
      expect(method_call).to all(be_a(JayAPI::Elasticsearch::Stats::Index))
    end

    it 'includes the expected list of indices' do
      # #to_a is needed here because of the lazy enumerator.
      expect(method_call.map(&:name).to_a).to eq(expected_indices)
    end
  end

  describe '#all' do
    subject(:method_call) { indices.all }

    let(:expected_indices_size) { 5 }

    let(:expected_indices) do
      %w[xyz01_integration_test xyz01_unit_tests .kibana_views xyz02_manual_verification .backup]
    end

    it_behaves_like '#all'
  end

  describe '#system' do
    subject(:method_call) { indices.system }

    let(:expected_indices_size) { 2 }
    let(:expected_indices) { %w[.kibana_views .backup] }

    it_behaves_like '#all'
  end

  describe '#user' do
    subject(:method_call) { indices.user }

    let(:expected_indices_size) { 3 }

    let(:expected_indices) do
      %w[xyz01_integration_test xyz01_unit_tests xyz02_manual_verification]
    end

    it_behaves_like '#all'
  end
end
