# frozen_string_literal: true

require 'jay_api/elasticsearch/indices/settings'
require 'jay_api/elasticsearch/indices/settings/blocks'

RSpec.describe JayAPI::Elasticsearch::Indices::Settings::Blocks do
  subject(:blocks) { described_class.new(settings) }

  let(:blocks_settings) do
    { 'read_only_allow_delete' => 'false', 'write' => 'false' }
  end

  let(:index_settings) do
    {
      'number_of_shards' => '5',
      'blocks' => blocks_settings,
      'provided_name' => 'xyz01_tests',
      'creation_date' => '1588701800423',
      'number_of_replicas' => '1',
      'uuid' => 'VFx2e5t0Qgi-1zc2PUkYEg',
      'version' => { 'created' => '7010199', 'upgraded' => '7100299' }
    }
  end

  let(:settings) do
    instance_double(
      JayAPI::Elasticsearch::Indices::Settings,
      all: index_settings,
      index_name: 'xyz01_tests'
    )
  end

  shared_examples_for '#blocks_settings' do
    it 'grabs the settings from the parent Settings object' do
      expect(settings).to receive(:all)
      method_call
    end

    context 'when fetching the settings causes an HTTP error to be raised' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::NotFound,
          '404 - Not Found'
        ]
      end

      before do
        allow(settings).to receive(:all).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    context 'when fetching the settings causes an KeyError to be raised' do
      let(:error) { [KeyError, 'key not found: "xyz01_tests"'] }

      before do
        allow(settings).to receive(:all).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    context 'when the returned settings do not contain the "blocks" key' do
      let(:index_settings) do
        super().except('blocks')
      end

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "blocks"'
        )
      end
    end
  end

  describe '#read_only?' do
    subject(:method_call) { blocks.write_blocked? }

    it_behaves_like '#blocks_settings'

    context 'when the "write" block is active' do
      let(:blocks_settings) { super().merge('write' => 'true') }

      it 'returns true' do
        expect(method_call).to be(true)
      end
    end

    context 'when the "write" block is inactive' do
      let(:blocks_settings) { super().merge('write' => 'false') }

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end

    context "when the response doesn't specify the status of the 'write' block" do
      let(:blocks_settings) { super().except('write') }

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(
          KeyError, 'key not found: "write"'
        )
      end
    end
  end

  shared_examples_for '#read_only=' do
    it 'takes the transport client from the parent Settings object' do
      expect(settings).to receive(:transport_client)
      method_call
    end

    it "uses the parent Settings object's transport client to set the settings" do
      expect(transport_client).to receive(:indices)
      expect(indices_client).to receive(:put_settings)
      method_call
    end

    context "when updating the index's settings raises an HTTP error" do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::RequestTimeout,
          '408 - Timed out'
        ]
      end

      before do
        allow(indices_client).to receive(:put_settings).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    it_behaves_like '#blocks_settings'
  end

  describe '#read_only=' do
    subject(:method_call) { blocks.write = value }

    let(:indices_client) do
      instance_double(
        Elasticsearch::API::Indices::IndicesClient,
        put_settings: true
      )
    end

    let(:transport_client) do
      instance_double(
        Elasticsearch::Transport::Client,
        indices: indices_client
      )
    end

    before do
      allow(settings).to receive(:transport_client).and_return(transport_client)
    end

    context "when 'value' is not a Boolean" do
      let(:value) { 'true' }

      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(
          ArgumentError, "Expected 'value' to be true or false, String given"
        )
      end
    end

    context 'when the value is set to true' do
      let(:value) { true }

      context 'when the index is already read-only' do
        let(:blocks_settings) { super().merge('write' => 'true') }

        it "does not try to set the index's settings" do
          expect(indices_client).not_to receive(:put_settings)
          method_call
        end
      end

      context 'when the index is not already read-only' do
        let(:blocks_settings) { super().merge('write' => 'false') }

        it_behaves_like '#read_only='

        it 'sets the expected index settings' do
          expect(indices_client).to receive(:put_settings).with(
            index: 'xyz01_tests', body: { 'blocks.write' => true }
          )

          method_call
        end
      end
    end

    context 'when the value is set to false' do
      let(:value) { false }

      context 'when the index is read-only' do
        let(:blocks_settings) { super().merge('write' => 'true') }

        it_behaves_like '#read_only='

        it 'sets the expected index settings' do
          expect(indices_client).to receive(:put_settings).with(
            index: 'xyz01_tests', body: { 'blocks.write' => false }
          )

          method_call
        end
      end

      context 'when the index is not read-only' do
        let(:blocks_settings) { super().merge('write' => 'false') }

        it "does not try to set the index's settings" do
          expect(indices_client).not_to receive(:put_settings)
          method_call
        end
      end
    end
  end
end
