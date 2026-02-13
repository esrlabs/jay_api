# frozen_string_literal: true

require 'jay_api/elasticsearch/indices/settings'

RSpec.describe JayAPI::Elasticsearch::Indices::Settings do
  subject(:settings) { described_class.new(transport_client, index_name) }

  let(:indices_client) do
    instance_double(
      Elasticsearch::API::Indices::IndicesClient
    )
  end

  let(:transport_client) do
    instance_double(
      Elasticsearch::Transport::Client,
      indices: indices_client
    )
  end

  let(:index_name) { 'xyz01_tests' }

  describe '#all' do
    subject(:method_call) { settings.all }

    let(:index_settings) do
      {
        'xyz01_tests' => {
          'settings' => {
            'index' => {
              'number_of_shards' => '5',
              'blocks' => { 'read_only_allow_delete' => 'false', 'write' => 'false' },
              'provided_name' => 'xyz01_tests',
              'creation_date' => '1588701800423',
              'number_of_replicas' => '1',
              'uuid' => 'VFx2e5t0Qgi-1zc2PUkYEg',
              'version' => { 'created' => '7010199', 'upgraded' => '7100299' }
            }
          }
        }
      }
    end

    let(:expected_hash) do
      {
        'number_of_shards' => '5',
        'blocks' => { 'read_only_allow_delete' => 'false', 'write' => 'false' },
        'provided_name' => 'xyz01_tests',
        'creation_date' => '1588701800423',
        'number_of_replicas' => '1',
        'uuid' => 'VFx2e5t0Qgi-1zc2PUkYEg',
        'version' => { 'created' => '7010199', 'upgraded' => '7100299' }
      }
    end

    before do
      allow(indices_client).to receive(:get_settings)
        .with(index: index_name).and_return(index_settings)
    end

    it "fetches the index's settings using the transport client" do
      expect(transport_client).to receive(:indices)
      expect(indices_client).to receive(:get_settings).with(index: index_name)
      method_call
    end

    it 'returns the expected hash' do
      expect(method_call).to eq(expected_hash)
    end

    context 'when an HTTP error occurs' do
      let(:error) do
        [
          Elasticsearch::Transport::Transport::Errors::Unauthorized,
          '401 - Unauthorized'
        ]
      end

      before do
        allow(indices_client).to receive(:get_settings).and_raise(*error)
      end

      it 're-raises the error' do
        expect { method_call }.to raise_error(*error)
      end
    end

    context "when the response doesn't contain the setting for the expected index" do
      let(:index_settings) do
        {
          'xyz01_requirements' => { # <== Different index
            'settings' => {
              'index' => {
                'routing' => { 'allocation' => { 'initial_recovery' => { '_id' => nil } } },
                'number_of_shards' => '5',
                'routing_partition_size' => '1',
                'blocks' => { 'read_only_allow_delete' => 'false', 'write' => 'false' },
                'provided_name' => 'xyz01_requirements',
                'creation_date' => '1770731215226',
                'number_of_replicas' => '1',
                'uuid' => 'M00JT4urRsSPRytAWObGCA',
                'version' => { 'created' => '135248027', 'upgraded' => '135248027' }
              }
            }
          }
        }
      end

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(KeyError, 'key not found: "xyz01_tests"')
      end
    end

    context "when the response doesn't contain the settings" do
      let(:index_settings) do
        {
          'xyz01_tests' => {}
        }
      end

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(KeyError, 'key not found: "settings"')
      end
    end

    context "when the response doesn't contain the index's settings" do
      let(:index_settings) do
        {
          'xyz01_tests' => {
            'settings' => {}
          }
        }
      end

      it 'raises a KeyError' do
        expect { method_call }.to raise_error(KeyError, 'key not found: "index"')
      end
    end
  end

  describe '#blocks' do
    subject(:method_call) { settings.blocks }

    let(:blocks) do
      instance_double(
        JayAPI::Elasticsearch::Indices::Settings::Blocks
      )
    end

    before do
      allow(JayAPI::Elasticsearch::Indices::Settings::Blocks).to receive(:new).and_return(blocks)
    end

    it 'creates an instance of the Blocks class with the expected parameters' do
      expect(JayAPI::Elasticsearch::Indices::Settings::Blocks).to receive(:new).with(settings)
      method_call
    end

    it 'returns the instance of the Blocks class' do
      expect(method_call).to be(blocks)
    end
  end
end
