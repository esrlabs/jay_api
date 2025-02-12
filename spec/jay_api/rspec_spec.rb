# frozen_string_literal: true

require 'jay_api/rspec/configuration'

RSpec.describe JayAPI::RSpec do
  subject(:rspec) { described_class }

  # rubocop:disable Rspec/VerifiedDoubles (cannot be used because of meta-programming)
  let(:configuration) do
    double(JayAPI::Configuration)
  end
  # rubocop:enable Rspec/VerifiedDoubles

  before do
    allow(JayAPI::Configuration).to receive(:from_file).and_return(configuration)
    allow(configuration).to receive(:is_a?).with(JayAPI::Configuration).and_return(true)
  end

  describe '.configuration' do
    subject(:method_call) { rspec.configuration }

    context 'when no configuration has been loaded' do
      before do
        # This is horrible, but there is no other way. Because the tests are
        # being executed in random order it may be that other test is executed
        # before this one, causing configuration to be loaded. And because the
        # configuration is meant to be globally accessible it is defined as an
        # instance variable of the RSpec module.
        described_class.instance_variable_set(:@configuration, nil)
      end

      it 'raises a JayAPI::Errors::ConfigurationError' do
        expect { method_call }.to raise_error(
          JayAPI::Errors::ConfigurationError,
          'No configuration has been set for the JayAPI::RSpec module. ' \
          'Please call JayAPI::RSpec.configure to load/create configuration.'
        )
      end
    end

    context 'when the configuration has been loaded' do
      before do
        rspec.configure { |config| config.from_file('configuration.yaml') }
      end

      it 'returns the configuration object' do
        expect(method_call).to eq(configuration)
      end
    end
  end

  describe '.configure' do
    it 'yields the JayAPI::Configuration class' do
      expect { |b| rspec.configure(&b) }
        .to yield_with_args(JayAPI::Configuration)
    end

    context 'when the return value is not an instance of JayAPI::Configuration' do
      let(:method_call) do
        rspec.configure { 'hello' }
      end

      it 'raises a JayAPI::Errors::ConfigurationError' do
        expect { method_call }.to raise_error(
          JayAPI::Errors::ConfigurationError,
          'Expected a JayAPI::Configuration or a subclass. Got a String instead.'
        )
      end
    end

    context 'when the return value is an instance of JayAPI::Configuration' do
      let(:method_call) do
        rspec.configure { configuration }
      end

      it 'assigns the given configuration object' do
        method_call
        expect(rspec.configuration).to eq(configuration)
      end
    end
  end
end
