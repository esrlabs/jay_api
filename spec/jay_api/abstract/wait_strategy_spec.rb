# frozen_string_literal: true

require 'jay_api/abstract/wait_strategy'

RSpec.describe JayAPI::Abstract::WaitStrategy do
  subject(:wait_strategy) { described_class.new(wait_interval: wait_interval, logger: logger) }

  let(:wait_interval) { 10 }
  let(:logger) { instance_double(Logging) }

  describe '#initialize' do
    subject(:method_call) { wait_strategy }

    shared_examples_for '#initialize when the logger is not specified' do
      before do
        allow(Logging).to receive(:logger)
      end

      it 'creates a new logger' do
        expect(Logging).to receive(:logger)

        method_call
      end
    end

    context 'when the logger is not specified' do
      let(:wait_strategy) { described_class.new(wait_interval: wait_interval) }

      it_behaves_like '#initialize when the logger is not specified'
    end

    context 'when the logger is set to nil' do
      let(:logger) { nil }

      it_behaves_like '#initialize when the logger is not specified'
    end

    context 'when the logger is specified' do
      it 'does not create a new logger' do
        expect(Logging).not_to receive(:logger)

        method_call
      end
    end
  end

  describe '#wait' do
    let(:method_call) { wait_strategy.wait }

    it 'raises NotImplementedError' do
      expect { method_call }.to raise_error(
        NotImplementedError, 'JayAPI::Abstract::WaitStrategy must implement the wait_time method'
      )
    end
  end
end
