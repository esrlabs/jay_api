# frozen_string_literal: true

require 'jay_api/configuration'

RSpec.shared_examples_for 'JayAPI::Configuration.from_string' do
  context 'when there is a disallowed class in the YAML' do
    let(:yaml) do
      <<~YAML
        --- !ruby/object:OpenStruct
        table: {}
      YAML
    end

    it 'raises a Psych::DisallowedClass error' do
      expect { method_call }.to raise_error(Psych::DisallowedClass)
    end
  end

  context "when the YAML parsing doesn't result on a Hash" do
    let(:yaml) do
      <<~YAML
        --- A simple string
        ...
      YAML
    end

    it 'raises a JayAPI::Errors::ConfigurationError error' do
      expect { method_call }.to raise_error(
        JayAPI::Errors::ConfigurationError,
        "Jay's configuration should be a set of key-value pairs."
      )
    end
  end

  context 'with a valid configuration YAML' do
    let(:yaml) do
      <<~YAML
        elasticsearch:
          cluster_url: https://jay.local
          port: 443
        project: xyz01
      YAML
    end

    it 'returns an instance of the class' do
      expect(method_call).to be_a(described_class)
    end

    it 'stores scalar values directly' do
      expect(method_call.project).to eq('xyz01')
    end

    it 'convert nested Hashes into JayAPI::Configuration classes' do
      expect(method_call.elasticsearch).to be_a(described_class)
    end

    it 'stores the nested values inside the nested classes' do
      expect(method_call.elasticsearch.cluster_url).to eq('https://jay.local')
      expect(method_call.elasticsearch.port).to eq(443)
    end
  end

  context 'with ERB code' do
    let(:yaml) do
      <<~YAML
        credentials:
          username: <%= ENV['USER'] %>
          password: <%= ENV['PASSWORD'] %>
      YAML
    end

    it 'parses the ERB segments on the string' do
      expect(method_call.credentials.username).to eq(ENV.fetch('USER', nil))
      expect(method_call.credentials.password).to eq(ENV.fetch('PASSWORD', nil))
    end
  end

  context 'with nested hashes inside arrays' do
    let(:yaml) do
      <<~YAML
        properties:
          url: 'https://xyz01-ci.local/job/Test/job/Test-Dev/'
          jobs:
            -
              name: CANoe
              active: true
            -
              name: Smoke-Test
              active: true
      YAML
    end

    it 'preserves the Array' do
      expect(method_call.properties.jobs).to be_an(Array)
    end

    it 'convert the inner hashes into JayAPI::Configuration classes' do
      expect(method_call.properties.jobs).to all(be_a(JayAPI::Configuration))
    end

    it 'allows standard array methods to be daisy chained' do
      expect(method_call.properties.jobs.first.name).to eq('CANoe')
      expect(method_call.properties.jobs.first.active).to be true
    end
  end
end

RSpec.describe JayAPI::Configuration do
  describe '.from_string' do
    subject(:method_call) { described_class.from_string(yaml) }

    it_behaves_like 'JayAPI::Configuration.from_string'
  end

  describe '.from_file' do
    subject(:method_call) { described_class.from_file(file_name) }

    let(:file_name) { 'config.yaml' }

    context "when the file doesn't exist" do
      before do
        allow(File).to receive(:read).with(file_name).and_raise(Errno::ENOENT, file_name)
      end

      it 'raises a Errno::ENOENT' do
        expect { method_call }.to raise_error(Errno::ENOENT, "No such file or directory - #{file_name}")
      end
    end

    context 'when the file exists' do
      before do
        allow(File).to receive(:read).with(file_name).and_return(yaml)
      end

      it_behaves_like 'JayAPI::Configuration.from_string'
    end
  end

  describe '#deep_to_h' do
    subject(:method_call) { configuration.deep_to_h }

    let(:configuration) do
      described_class.new(
        build_jpb: 'XYX01-Release-Master',
        build_number: 170,
        built_on: Time.new(2022, 10, 5, 13, 35, 20)
      )
    end

    let(:expected_hash) do
      {
        build_jpb: 'XYX01-Release-Master',
        build_number: 170,
        built_on: Time.new(2022, 10, 5, 13, 35, 20)
      }
    end

    context 'with a single level configuration' do
      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'with a nested JayAPI::Configuration object' do
      before do
        configuration.parameters = described_class.new(
          gerrit_patchset_revision: 'FETCH_HEAD',
          gerrit_refspec: 'refs/changes/35/15935/1'
        )

        expected_hash[:parameters] = {
          gerrit_patchset_revision: 'FETCH_HEAD',
          gerrit_refspec: 'refs/changes/35/15935/1'
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'with a nested Hash' do
      before do
        configuration.node = {
          name: 'muc-r03-xyz01-b03-linux',
          os: 'ubuntu 22.04',
          ip: '172.22.16.23'
        }

        expected_hash[:node] = {
          name: 'muc-r03-xyz01-b03-linux',
          os: 'ubuntu 22.04',
          ip: '172.22.16.23'
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'with a nested array' do
      before do
        configuration.credentials = [
          'AD_USER_XYZ01', 'jenkins-jira', 'jenkins gerrit user'
        ]

        expected_hash[:credentials] = [
          'AD_USER_XYZ01', 'jenkins-jira', 'jenkins gerrit user'
        ]
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'with a mixture of types' do
      before do
        configuration.stages = [
          1, 'Prepare Environment',
          2, 'Run Tests',
          3, 'Clean Up',
          4, {
            'Post-Build': described_class.new(
              publish_html_reports: true,
              archive_artifacts: true,
              clean_ws: true
            )
          }
        ]

        expected_hash[:stages] = [
          1, 'Prepare Environment',
          2, 'Run Tests',
          3, 'Clean Up',
          4, {
            'Post-Build': {
              publish_html_reports: true,
              archive_artifacts: true,
              clean_ws: true
            }
          }
        ]
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end

  describe '#to_yaml' do
    subject(:method_call) { described_class.from_string(yaml).to_yaml }

    let(:yaml) do
      <<~YAML
        elasticsearch:
          index_name: hcpx_tests
          credentials:
            username: <%= 'Tom' %>
            password: <%= '123' * 5 %>
      YAML
    end

    let(:expected_yaml_string) do
      <<~TEXT
        ---
        elasticsearch:
          index_name: hcpx_tests
          credentials:
            username: Tom
            password: 123123123123123
      TEXT
    end

    it 'prints the configuration as a parsed YAML string' do
      expect(method_call).to eq(expected_yaml_string)
    end
  end
end
