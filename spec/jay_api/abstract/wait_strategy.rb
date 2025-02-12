# frozen_string_literal: true

RSpec.shared_examples_for 'WaitStrategy#wait' do
  # requires this variable to be defined: :expected_wait_time

  let(:nr_of_previous_wait_calls) { rand(10) }

  before do
    allow(Kernel).to receive(:sleep)
    allow(logger).to receive(:info)
    nr_of_previous_wait_calls.times { wait_strategy.wait }
  end

  it 'sleeps the specified constant amount of time' do
    expect(Kernel).to receive(:sleep).with(expected_wait_time)

    method_call
  end

  it 'logs the sleep time' do
    expect(logger).to receive(:info).with("Sleeping: #{format('%.2f', expected_wait_time)} s")

    method_call
  end
end
