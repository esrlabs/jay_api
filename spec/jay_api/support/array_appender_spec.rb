# frozen_string_literal: true

require_relative '../../support/array_appender'

RSpec.describe ArrayAppender do
  subject(:appender) { described_class.new('test_appender') }

  let(:logger) { Logging.logger['test_logger'] }

  before do
    logger.add_appenders(appender)
    logger.level = :info
  end

  after do
    Logging.logger['test_logger'].remove_appenders('test_appender')
  end

  describe '#initialize' do
    it 'initializes with an empty logs array' do
      expect(appender.logs).to be_empty
    end
  end

  shared_examples_for 'ArrayAppender#logs' do
    context 'with a single message' do
      before do
        logger.info 'Test log message'
      end

      it 'captures log messages' do
        expect(method_call).to eq(expected_single_message)
      end
    end

    context 'with multiple messages' do
      before do
        logger.info 'Test log message'
        logger.info 'Test log message 2'
        logger.info 'Test log message 3'
      end

      it 'captures log messages' do
        expect(method_call).to eq(expected_multiple_messages)
      end
    end
  end

  describe '#logs' do
    subject(:method_call) { appender.logs }

    let(:expected_single_message) { ['Test log message'] }
    let(:expected_multiple_messages) { ['Test log message', 'Test log message 2', 'Test log message 3'] }

    it_behaves_like 'ArrayAppender#logs'
  end

  describe '#to_s' do
    subject(:method_call) { appender.to_s }

    let(:expected_single_message) { 'Test log message' }
    let(:expected_multiple_messages) { "Test log message\nTest log message 2\nTest log message 3" }

    it_behaves_like 'ArrayAppender#logs'
  end
end
