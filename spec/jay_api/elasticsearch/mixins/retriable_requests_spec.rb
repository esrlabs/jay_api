# frozen_string_literal: true

require 'jay_api/elasticsearch/mixins/retriable_requests'

RSpec.describe JayAPI::Elasticsearch::Mixins::RetriableRequests do
  subject(:test_instance) do
    test_class.new
  end

  let(:test_class) do
    Class.new do
      include JayAPI::Elasticsearch::Mixins::RetriableRequests
    end
  end

  describe '#max_attempts' do
    subject(:method_call) { test_instance.max_attempts }

    it 'raises a NotImplementedError' do
      expect { method_call }.to raise_error(
        NotImplementedError,
        include('Please implement the method #max_attempts in #<Class')
      )
    end
  end

  describe '#wait_strategy' do
    subject(:method_call) { test_instance.wait_strategy }

    it 'raises a NotImplementedError' do
      expect { method_call }.to raise_error(
        NotImplementedError,
        include('Please implement the method #wait_strategy in #<Class')
      )
    end
  end

  describe '#logger' do
    subject(:method_call) { test_instance.logger }

    it 'raises a NotImplementedError' do
      expect { method_call }.to raise_error(
        NotImplementedError,
        include('Please implement the method #logger in #<Class')
      )
    end
  end

  describe '#retriable_errors' do
    subject(:method_call) { test_instance.retriable_errors }

    let(:expected_errors) do
      [
        Elasticsearch::Transport::Transport::ServerError,
        Faraday::TimeoutError
      ]
    end

    it 'returns the expected array of errors' do
      expect(method_call).to match_array(expected_errors)
    end
  end

  describe '#non_retriable_errors' do
    subject(:method_call) { test_instance.non_retriable_errors }

    let(:expected_errors) do
      [
        Elasticsearch::Transport::Transport::Errors::BadRequest,
        Elasticsearch::Transport::Transport::Errors::Unauthorized,
        Elasticsearch::Transport::Transport::Errors::Forbidden,
        Elasticsearch::Transport::Transport::Errors::NotFound,
        Elasticsearch::Transport::Transport::Errors::MethodNotAllowed,
        Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
        Elasticsearch::Transport::Transport::Errors::NotImplemented
      ]
    end

    it 'returns the expected array of errors' do
      expect(method_call).to match_array(expected_errors)
    end
  end
end
