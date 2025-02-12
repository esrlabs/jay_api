# frozen_string_literal: true

require 'jay_api/mergeables/merge_selector'

RSpec.describe JayAPI::Configuration do
  subject(:configuration) { described_class.from_string(yaml_input) }

  let(:yaml_input) do
    <<~YAML
      some: yaml
    YAML
  end

  let(:expected_hash) do
    {
      some: 'yaml'
    }
  end

  describe '#with_merge_selector' do
    subject(:with_merge_selector) { configuration.with_merge_selector }

    it 'returns an instance of MergeSelector::Configuration' do
      expect(with_merge_selector).to be_instance_of(JayAPI::Mergeables::MergeSelector::Configuration)
    end

    it 'contains the same configuration as the original configuration' do
      expect(with_merge_selector.deep_to_h).to eq(expected_hash)
    end
  end
end
