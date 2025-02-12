# frozen_string_literal: true

require 'jay_api/id_builder'

RSpec.shared_examples_for 'JayAPI::IDBuilder#short_id with missing parameters' do
  let(:error_message) do
    "The Test Case ID (test_case_id) and the Project's name (project) are " \
      'required to calculate the Short ID'
  end

  it 'raises an ArgumentError' do
    expect { builder.short_id }.to raise_error(ArgumentError, error_message)
  end
end

RSpec.shared_examples_for 'JayAPI::IDBuilder#secure_id with missing parameters' do
  let(:error_message) do
    'The Software Version (software_version) and the Result (result) are ' \
      'required to calculate the Secure ID'
  end

  it 'raises an ArgumentError' do
    expect { builder.secure_id }.to raise_error(ArgumentError, error_message)
  end
end

RSpec.describe JayAPI::IDBuilder do
  describe '#short_id' do
    subject(:builder) do
      described_class.new(test_case_id: test_case_id, project: project)
    end

    let(:test_case_id) do
      'Routing/PDU Routing: CAN to CAN/ISOND_01/Routes an ISOND_01 from XYZ01_CANFD05 to XYZ01_CANFD01'
    end

    let(:project) { 'XYZ01' }

    context 'when test_case_id is not provided' do
      let(:test_case_id) { nil }

      it_behaves_like 'JayAPI::IDBuilder#short_id with missing parameters'
    end

    context 'when project is not provided' do
      let(:project) { nil }

      it_behaves_like 'JayAPI::IDBuilder#short_id with missing parameters'
    end

    it 'generates the expected Short ID' do
      expect(builder.short_id).to eq('xyz01_6ce3440a5e0e')
    end

    context 'when the ID of the testcases differ by a minus sing' do
      let(:test_case_id_a) do
        'SF-Integration/EEM/TC 10: EEM interface tests/HCAN::BMC_MLBevo::BMS_01/Signal: BMS_IstStrom_02, Value: -2047.0'
      end

      let(:test_case_id_b) do
        'SF-Integration/EEM/TC 10: EEM interface tests/HCAN::BMC_MLBevo::BMS_01/Signal: BMS_IstStrom_02, Value: 2047.0'
      end

      let(:builder_a) { described_class.new(test_case_id: test_case_id_a, project: project) }
      let(:builder_b) { described_class.new(test_case_id: test_case_id_b, project: project) }

      it 'does not generate the same ID' do
        expect(builder_a.short_id).not_to eq(builder_b.short_id)
      end
    end
  end

  describe '#secure_id' do
    subject(:builder) do
      described_class.new(software_version: software_version, result: result)
    end

    let(:software_version) { 'X010' }
    let(:result) { 'passed' }

    let(:uuid) { '4604780c-0570-4840-ab67-c1f40fb24641' }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
    end

    context 'when software_version is not provided' do
      let(:software_version) { nil }

      it_behaves_like 'JayAPI::IDBuilder#secure_id with missing parameters'
    end

    context 'when result is not provided' do
      let(:result) { nil }

      it_behaves_like 'JayAPI::IDBuilder#secure_id with missing parameters'
    end

    it 'generates the expected Secure ID and Secure Seed' do
      expect(builder.secure_id).to eq([uuid, 'cf82cde620a4daba89cf409b73fc5128'])
    end
  end
end
