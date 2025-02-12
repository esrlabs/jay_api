# frozen_string_literal: true

require 'jay_api/abstract/constant_wait'

require_relative 'wait_strategy'

RSpec.describe JayAPI::Abstract::ConstantWait do
  subject(:wait_strategy) { described_class.new(wait_interval: wait_interval, logger: logger) }

  let(:wait_interval) { 10 }

  # rubocop:disable RSpec/VerifiedDoubles (Cannot be used because of meta-programming)
  let(:logger) { double(Logging::Logger) }
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#wait' do
    subject(:method_call) { wait_strategy.wait }

    let(:expected_wait_time) { wait_interval }

    it_behaves_like 'WaitStrategy#wait'
  end
end
