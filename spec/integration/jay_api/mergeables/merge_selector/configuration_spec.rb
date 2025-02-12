# frozen_string_literal: true

require 'jay_api/mergeables/merge_selector/configuration'

RSpec.describe JayAPI::Mergeables::MergeSelector::Configuration do
  subject(:default_config) do
    described_class.from_string(default_config_yaml)
  end

  let(:default_config_yaml) do
    File.read(
      File.join(
        __dir__, 'default_config.yaml'
      )
    )
  end

  let(:another_configuration) do
    described_class.from_string(selector_config_yaml)
  end

  let(:selector_config_yaml) do
    File.read(
      File.join(
        __dir__, 'selector_config.yaml'
      )
    )
  end

  let(:result_configuration) do
    described_class.from_string(result_config_yaml)
  end

  let(:result_config_yaml) do
    File.read(
      File.join(
        __dir__, 'result_config.yaml'
      )
    )
  end

  describe '#merge_select' do
    subject(:merge_select) { default_config.merge_select(another_configuration) }

    it 'merges the configurations as expected in the result_config.yaml' do
      expect(merge_select.deep_to_h).to eq(result_configuration.deep_to_h)
    end
  end
end
