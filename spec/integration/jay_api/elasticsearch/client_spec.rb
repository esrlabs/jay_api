# frozen_string_literal: true

require 'jay_api/elasticsearch/client_factory'

RSpec.describe JayAPI::Elasticsearch::Client do
  subject(:client) { JayAPI::Elasticsearch::ClientFactory.new(cluster_url: 'https://www.es.com').create }

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

  let(:method_call) { client.send(method_name, **client_method_arguments) }

  before do
    allow(Elasticsearch::Client).to receive(:new).with(
      hosts: [host],
      log: false
    ).and_return(transport_client)
  end

  shared_examples_for 'JayAPI::Elasticsearch::Client#<any_method>' do
    let(:transport_response) { { some: :response } }

    context 'when no error is raised by the Elasticsearch Client' do
      before do
        allow(used_client).to receive(client_method_name).with(client_method_arguments).and_return(transport_response)
      end

      it 'does not raise an Error' do
        expect { method_call }.not_to raise_error
      end

      it 'passes the arguments to the Elasticsearch Client once' do
        expect(used_client).to receive(client_method_name).with(client_method_arguments).once

        method_call
      end

      it "returns the Elasticsearch Client's return value" do
        expect(method_call).to be(transport_response)
      end
    end

    context 'when the error is raised by the Elasticsearch Client' do
      shared_examples_for '#<any_method> when ::Elasticsearch::Transport::Client raises an error' do
        context 'when the error does not occur more than the maximum allowed number of times' do
          before do
            # raises an error two times and after that returns a response
            total_times = 2
            times = 0
            allow(used_client).to receive(client_method_name).with(client_method_arguments) do
              times += 1
              raise server_error if times <= total_times

              transport_response
            end

            allow(Kernel).to receive(:sleep).with(2)
            allow(Kernel).to receive(:sleep).with(4)
          end

          it 'does not raise the error' do
            expect { method_call }.not_to raise_error
          end

          # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
          it 'waits an increasing amount of time until it returns the response' do
            expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered
            expect(Kernel).to receive(:sleep).with(2).ordered
            expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered
            expect(Kernel).to receive(:sleep).with(4).ordered
            expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered

            expect(method_call).to be(transport_response)
          end
          # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
        end

        context 'when it is raised more than the maximum number of allowed times' do
          before do
            allow(used_client).to receive(client_method_name).and_raise(server_error)

            allow(Kernel).to receive(:sleep).with(2)
            allow(Kernel).to receive(:sleep).with(4)
            allow(Kernel).to receive(:sleep).with(8)
          end

          it 'raises the error' do
            expect { method_call }.to raise_error(server_error)
          end

          shared_examples_for 'Client retrying connection' do
            # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
            it 'waits a compounding number of seconds until it reaches a limit and raises an error' do
              expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered
              expect(Kernel).to receive(:sleep).with(2).ordered
              expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered
              expect(Kernel).to receive(:sleep).with(4).ordered
              expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered
              expect(Kernel).to receive(:sleep).with(8).ordered
              expect(used_client).to receive(client_method_name).with(client_method_arguments).once.ordered

              expect { method_call }.to raise_error(server_error)
            end
            # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
          end

          context 'when Client was not yet called' do
            it_behaves_like 'Client retrying connection'
          end

          context 'when client was already called' do
            # rubocop:disable RSpec/ExpectInHook
            before do
              expect { client.send(method_name, **client_method_arguments) }.to raise_error(server_error)
            end
            # rubocop:enable RSpec/ExpectInHook

            it_behaves_like 'Client retrying connection'
          end
        end
      end

      shared_examples_for '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error' do
        before do
          allow(used_client).to receive(client_method_name).and_raise(server_error)
        end

        it 'only calls the method once and raises the error' do
          expect(used_client).to receive(client_method_name).once
          expect { method_call }.to raise_error(server_error)
        end

        it 'does not sleep and raises the error' do
          expect(Kernel).not_to receive(:sleep)
          expect { method_call }.to raise_error(server_error)
        end
      end

      context 'when a ServerError is raised' do
        let(:server_error) { Elasticsearch::Transport::Transport::ServerError.new('Too Many Requests') }

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises an error'
      end

      context 'when a TimeoutError is raised' do
        let(:server_error) { Faraday::TimeoutError.new('Chill out') }

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises an error'
      end

      context 'when a BadRequest error is raised' do
        let(:server_error) { Elasticsearch::Transport::Transport::Errors::BadRequest.new('JSON parsing error') }

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when an Unauthorized error is raised' do
        let(:server_error) { Elasticsearch::Transport::Transport::Errors::Unauthorized.new('Authentication failed') }

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when a Forbidden error is raised' do
        let(:server_error) do
          Elasticsearch::Transport::Transport::Errors::Forbidden.new(
            'user svc.p.xyz01 missing permission delete_index'
          )
        end

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when a NotFound error is raised' do
        let(:server_error) do
          Elasticsearch::Transport::Transport::Errors::NotFound.new('No such index xyz01_integration_test')
        end

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when a MethodNotAllowed error is raised' do
        let(:server_error) do
          Elasticsearch::Transport::Transport::Errors::MethodNotAllowed.new(
            'Incorrect HTTP method [GET], allowed: [POST]'
          )
        end

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when a RequestEntityTooLarge error is raised' do
        let(:server_error) do
          Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge.new(
            'Request is too big: 2168220 bytes (maximum is 1024000 bytes)'
          )
        end

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end

      context 'when a NotImplemented error is raised' do
        let(:server_error) do
          Elasticsearch::Transport::Transport::Errors::NotImplemented.new('Feature not implemented')
        end

        it_behaves_like '#<any_method> when ::Elasticsearch::Transport::Client raises a non-retriable error'
      end
    end
  end

  describe '#index' do
    let(:method_name) { :index }
    let(:client_method_arguments) { { index: 'asd', type: 'bye', body: {} } }
    let(:used_client) { transport_client }
    let(:client_method_name) { :index }

    it_behaves_like 'JayAPI::Elasticsearch::Client#<any_method>'
  end

  describe '#search' do
    let(:method_name) { :search }
    let(:client_method_arguments) { { search: :params } }
    let(:used_client) { transport_client }
    let(:client_method_name) { :search }

    it_behaves_like 'JayAPI::Elasticsearch::Client#<any_method>'
  end

  describe '#bulk' do
    let(:method_name) { :bulk }
    let(:client_method_arguments) { { body: { some: :body } } }
    let(:used_client) { transport_client }
    let(:client_method_name) { :bulk }

    it_behaves_like 'JayAPI::Elasticsearch::Client#<any_method>'
  end

  describe '#delete_by_query' do
    let(:method_name) { :delete_by_query }

    let(:client_method_arguments) do
      {
        index: 'xyz01_integration_test',
        body: { query: { match_all: {} } }
      }
    end

    let(:used_client) { transport_client }
    let(:client_method_name) { :delete_by_query }

    it_behaves_like 'JayAPI::Elasticsearch::Client#<any_method>'
  end

  describe '#task_by_id' do
    let(:method_name) { :task_by_id }

    let(:client_method_arguments) do
      {
        index: 'xyz01_integration_test',
        task_id: 'B5oDyEsHQu2Q-wpbaMSMTg:577411212',
        wait_for_completion: true
      }
    end

    let(:tasks_client) do
      instance_double(
        Elasticsearch::API::Tasks::TasksClient,
        get: transport_response
      )
    end

    let(:used_client) { tasks_client }
    let(:client_method_name) { :get }

    before do
      allow(transport_client).to receive(:tasks).and_return(tasks_client)
    end

    it_behaves_like 'JayAPI::Elasticsearch::Client#<any_method>'
  end

  describe '#ping' do
    subject(:method_call) { client.ping }

    it 'forwards the call to the underlying transport client' do
      expect(transport_client).to receive(:ping)
      method_call
    end
  end
end
