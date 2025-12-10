# frozen_string_literal: true

require 'jay_api/elasticsearch/client_factory'

RSpec.shared_examples_for 'ClientFactory initializing the Transport Client' do
  it 'creates a JayAPI::Elasticsearch::Client object' do
    expect(client).to be_instance_of(JayAPI::Elasticsearch::Client)
  end

  it 'wraps the Elasticsearch Client' do
    expect(client.transport_client).to be(transport_client)
  end

  context 'when only the cluster URL is specified' do
    let(:host) do
      {
        host: 'www.es.com',
        port: 9200,
        scheme: 'https'
      }
    end

    it 'defaults to using 9200 as a port number' do
      expect(Elasticsearch::Client).to receive(:new).with(
        { hosts: [host], log: false }
      )

      client
    end
  end

  context 'when the port is specified' do
    let(:constructor_params) { super().merge(port: 1234) }

    let(:host) do
      {
        host: 'www.es.com',
        port: 1234,
        scheme: 'https'
      }
    end

    it 'uses the specified port number' do
      expect(Elasticsearch::Client).to receive(:new).with(
        { hosts: [host], log: false }
      )

      client
    end
  end

  context 'when the credentials are specified' do
    let(:constructor_params) { super().merge(username: 'Koala', password: 'Bear') }

    let(:host) do
      {
        host: 'www.es.com',
        port: 9200,
        scheme: 'https',
        user: 'Koala',
        password: 'Bear'
      }
    end

    it 'initializes the Elasticsearch Client with the correct credentials' do
      expect(Elasticsearch::Client).to receive(:new).with(
        { hosts: [host], log: false }
      )

      client
    end
  end

  context 'when no timeout is given' do
    it "initializes the Elasticsearch Client without the 'request_timeout' parameter" do
      expect(Elasticsearch::Client).to receive(:new).with(
        { hosts: [host], log: false }
      )

      client
    end
  end

  context 'when a timeout is given' do
    let(:create_params) { super().merge(timeout: 300) }

    it "initializes the Elasticsearch Client with the expected 'request_timeout' parameter" do
      expect(Elasticsearch::Client).to receive(:new).with(
        { hosts: [host], log: false, request_timeout: 300 }
      )

      client
    end
  end
end

RSpec.describe JayAPI::Elasticsearch::ClientFactory do
  subject(:client_factory) { described_class.new(**constructor_params) }

  let(:constructor_params) do
    { cluster_url: 'https://www.es.com' }
  end

  shared_examples_for '#create' do
    it_behaves_like 'ClientFactory initializing the Transport Client'

    it 'chooses a default wait strategy' do
      expect(client.wait_strategy).to be_instance_of(expected_wait_strategy)
    end

    it 'sets a default wait interval' do
      expect(client.wait_strategy.wait_interval).to be(expected_wait_interval)
    end

    it 'sets a default max attempts number' do
      expect(client.max_attempts).to be(expected_max_attempts)
    end
  end

  describe '#create' do
    subject(:client) { client_factory.create(**create_params) }

    let(:create_params) { {} }

    let(:host) do
      {
        host: 'www.es.com',
        port: 9200,
        scheme: 'https'
      }
    end

    let(:transport_client) do
      instance_double(Elasticsearch::Transport::Client)
    end

    let(:expected_wait_strategy) { JayAPI::Abstract::GeometricWait }
    let(:expected_wait_interval) { 2 }
    let(:expected_max_attempts) { 4 }

    before do
      allow(Elasticsearch::Client).to receive(:new).and_return(transport_client)
    end

    context 'without any specified parameters' do
      let(:create_params) { {} }

      it_behaves_like '#create'
    end

    context "when specifying the 'wait_strategy' param" do
      context "with 'geometric'" do
        let(:create_params) { super().merge(wait_strategy: :geometric) }
        let(:expected_wait_strategy) { JayAPI::Abstract::GeometricWait }

        it_behaves_like '#create'
      end

      context "with 'constant'" do
        let(:create_params) { super().merge(wait_strategy: :constant) }
        let(:expected_wait_strategy) { JayAPI::Abstract::ConstantWait }

        it_behaves_like '#create'
      end
    end

    context "when specifying the 'max_attempts' param" do
      let(:create_params) { super().merge(max_attempts: expected_max_attempts) }
      let(:expected_max_attempts) { 100 }

      it_behaves_like '#create'
    end

    context "when specifying the 'wait_interval' param" do
      let(:create_params) { super().merge(wait_interval: expected_wait_interval) }
      let(:expected_wait_interval) { 399 }

      it_behaves_like '#create'
    end
  end
end
