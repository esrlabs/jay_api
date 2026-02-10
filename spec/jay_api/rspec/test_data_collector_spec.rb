# frozen_string_literal: true

require 'jay_api/rspec/test_data_collector'

RSpec.shared_context 'when JayAPI::RSpec is configured' do
  let(:push_enabled) { nil }
  let(:elasticsearch_config) { nil }
  let(:project) { 'jay_api' }

  let(:configuration_hash) do
    {
      push_enabled: push_enabled,
      elasticsearch: elasticsearch_config,
      project: project
    }
  end

  # rubocop:disable Rspec/VerifiedDoubles (cannot be used because of meta-programming)
  let(:configuration) do
    double(
      JayAPI::Configuration,
      to_h: configuration_hash,
      **configuration_hash
    )
  end
  # rubocop:enable Rspec/VerifiedDoubles

  before do
    allow(JayAPI::RSpec).to receive(:configuration).and_return(configuration)
  end
end

RSpec.shared_context 'when JayAPI::RSpec has Elasticsearch configuration' do
  let(:cluster_url) { 'https://elasticsearch.local' }
  let(:index_name) { 'jay_api_tests' }

  # The range should not contain DEFAULT_BATCH_SIZE
  let(:batch_size) { rand(120..200) }

  let(:elasticsearch_config_hash) do
    {
      cluster_url: cluster_url,
      index_name: index_name,
      batch_size: batch_size
    }
  end

  # rubocop:disable RSpec/VerifiedDoubles (Cannot be used because of meta-programming)
  let(:elasticsearch_config) do
    double(
      JayAPI::Configuration,
      to_h: elasticsearch_config_hash
    )
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

RSpec.shared_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch' do
  shared_examples_for '#example_finished when a type has been specified in the configuration' do
    it 'pushes the expected data to the Elasticsearch Index with the expected type' do
      expect(elasticsearch_index).to receive(:push).with(expected_data, type: expected_type)
      method_call
    end
  end

  context 'when no type has been specified in the configuration' do
    it 'pushes the expected data to the Elasticsearch Index' do
      expect(elasticsearch_index).to receive(:push).with(expected_data)
      method_call
    end
  end

  context 'when a type is specified in the configuration' do
    let(:configuration_hash) do
      super().merge(type: 'nested')
    end

    let(:expected_type) { 'nested' }

    it_behaves_like '#example_finished when a type has been specified in the configuration'
  end

  context 'when a nil is specified in the configuration as type' do
    let(:configuration_hash) do
      super().merge(type: nil)
    end

    let(:expected_type) { nil }

    it_behaves_like '#example_finished when a type has been specified in the configuration'
  end
end

RSpec.describe JayAPI::RSpec::TestDataCollector do
  subject(:test_data_collector) { described_class.new(nil) }

  let(:client) do
    JayAPI::Elasticsearch::Client
  end

  let(:client_factory) do
    instance_double(
      JayAPI::Elasticsearch::ClientFactory,
      create: client
    )
  end

  let(:elasticsearch_index) do
    instance_double(
      JayAPI::Elasticsearch::Index
    )
  end

  before do
    allow(JayAPI::Elasticsearch::ClientFactory).to receive(:new).and_return(client_factory)
    allow(JayAPI::Elasticsearch::Index).to receive(:new).and_return(elasticsearch_index)
  end

  describe '#start' do
    subject(:method_call) { test_data_collector.start(nil) }

    context 'when JayPI::RSpec is not configured' do
      before do
        allow(JayAPI::RSpec).to receive(:configuration).and_raise(
          JayAPI::Errors::ConfigurationError,
          'No configuration has been set for the JayAPI::RSpec module. ' \
          'Please call JayAPI::RSpec.configure to load/create configuration.'
        )
      end

      it 'raises a JayAPI::Errors::ConfigurationError' do
        expect { method_call }.to raise_error(
          JayAPI::Errors::ConfigurationError,
          'No configuration has been set for the JayAPI::RSpec module. ' \
          'Please call JayAPI::RSpec.configure to load/create configuration.'
        )
      end
    end

    context 'when JayPI::RSpec is configured' do
      include_context 'when JayAPI::RSpec is configured'

      context 'when the data push is disabled' do
        it 'does not try to load the Elasticsearch configuration' do
          expect(configuration).not_to receive(:elasticsearch)
          method_call
        end

        it 'does not initialize the Elasticsearch Index' do
          expect(JayAPI::Elasticsearch::Index).not_to receive(:new)
          method_call
        end
      end

      context 'when the data push is enabled' do
        let(:push_enabled) { true }

        context 'when there is no Elasticsearch configuration' do
          it 'raises a JayAPI::Errors::ConfigurationError' do
            expect { method_call }.to raise_error(
              JayAPI::Errors::ConfigurationError,
              'No Elasticsearch configuration provided for the JayAPI::RSpec module.'
            )
          end
        end

        context 'when there is Elasticsearch config' do
          include_context 'when JayAPI::RSpec has Elasticsearch configuration'

          context 'when one of the required keys is missing' do
            before do
              elasticsearch_config_hash.delete(:cluster_url)

              # The following line removes the mock on the ClientFactory class
              # to allow the error to be raised from the actual constructor.
              allow(JayAPI::Elasticsearch::ClientFactory).to receive(:new).and_call_original
            end

            it 'raises an ArgumentError' do
              expect { method_call }.to raise_error(ArgumentError, 'missing keyword: :cluster_url')
            end
          end

          it 'uses the ClientFactory class to create an Elasticsearch::Client' do
            expect(JayAPI::Elasticsearch::ClientFactory)
              .to receive(:new).with(cluster_url: cluster_url)

            expect(client_factory).to receive(:create)
            method_call
          end

          shared_examples 'Elasticsearch::Index initialization' do
            it 'initializes the Elasticsearch::Index instance with the expected parameters' do
              expect(JayAPI::Elasticsearch::Index).to receive(:new).with(
                client: client, index_name: index_name, batch_size: expected_batch_size
              )

              method_call
            end
          end

          context 'when no batch_size has been provided' do
            let(:expected_batch_size) { described_class::DEFAULT_BATCH_SIZE }

            before { elasticsearch_config_hash.delete(:batch_size) }

            include_examples 'Elasticsearch::Index initialization'
          end

          context 'when a batch size has been given' do
            let(:expected_batch_size) { batch_size }

            include_examples 'Elasticsearch::Index initialization'
          end
        end
      end
    end
  end

  describe '#example_finished' do
    subject(:method_call) { test_data_collector.example_finished(notification) }

    let(:exception) { nil }
    let(:status) { :passed }

    let(:execution_result) do
      instance_double(
        RSpec::Core::Example::ExecutionResult,
        started_at: Time.gm(2021, 12, 21, 21, 12, 12),
        finished_at: Time.gm(2021, 12, 21, 21, 12, 21),
        run_time: 9,
        status: status,
        exception: exception
      )
    end

    let(:description) { 'returns the configuration object' }

    let(:full_description) do
      "JayAPI::RSpec::#configure when the configuration has been loaded #{description}"
    end

    let(:location) { 'spec/jay_api/rspec_spec.rb:46' }
    let(:requirements) { %w[JAY_API_3154 JAY_API_962] }
    let(:refs) { nil }

    let(:expected_requirements) { requirements }

    let(:metadata) do
      {
        location: location,
        requirements: requirements,
        refs: refs
      }
    end

    let(:example) do
      instance_double(
        RSpec::Core::Example,
        description: description,
        execution_result: execution_result,
        full_description: full_description,
        metadata: metadata
      )
    end

    let(:notification) do
      instance_double(
        RSpec::Core::Notifications::ExampleNotification,
        example: example
      )
    end

    let(:build_number) { 1024 }
    let(:build_job_name) { 'Elite/jay_api' }
    let(:revision_sha1) { 'b76b7418ec96894ff320897eb358ca11c6d26eae' }
    let(:hostname) { `hostname`.chomp }

    let(:commit) do
      instance_double(
        Git::Object::Commit,
        sha: revision_sha1
      )
    end

    let(:git_log) do
      instance_double(
        Git::Log,
        first: commit
      )
    end

    let(:remote_url) { 'ssh://gerrit.local/tools/jay/jay_api' }

    let(:repository) do
      instance_double(
        JayAPI::Git::Repository,
        log: git_log,
        remote_url: remote_url
      )
    end

    let(:short_id) { 'jay_api_424dd80eea73' }

    let(:id_builder) do
      instance_double(
        JayAPI::IDBuilder,
        short_id: short_id
      )
    end

    let(:expected_result) { 'pass' }
    let(:exception_message) { nil }

    let(:expected_data) do
      {
        test_env: {
          build_number: build_number,
          build_job_name: build_job_name,
          revision: revision_sha1,
          repository: remote_url,
          hostname: hostname
        },
        test_case: {
          name: full_description,
          started_at: '2021/12/21 21:12:12',
          finished_at: '2021/12/21 21:12:21',
          runtime: 9,
          id_long: full_description,
          id: short_id,
          location: location,
          requirements: expected_requirements,
          expectation: description,
          result: expected_result,
          exception: exception_message
        }
      }
    end

    include_context 'when JayAPI::RSpec is configured'
    include_context 'when JayAPI::RSpec has Elasticsearch configuration'

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('BUILD_NUMBER').and_return(build_number)
      allow(ENV).to receive(:[]).with('JOB_NAME').and_return(build_job_name)

      allow(JayAPI::Git::Repository).to receive(:new)
        .with(url: nil, clone_path: Dir.pwd).and_return(repository)

      allow(JayAPI::IDBuilder).to receive(:new)
        .with(test_case_id: full_description, project: project).and_return(id_builder)
    end

    context 'when the data push is disabled' do
      # Empty doubles, any method call on them will make the test fail (This is
      # done to make sure the method is not doing anything)
      let(:notification) { double }
      let(:elasticsearch_index) { double }

      it 'does nothing' do
        expect { method_call }.not_to raise_error
      end
    end

    context 'when the data push is enabled' do
      let(:push_enabled) { true }

      include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'

      context 'when no BUILD_NUMBER nor JOB_NAME are defined' do
        let(:build_job_name) { nil }
        let(:build_number) { nil }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when the Git::Repository class cannot be initialized' do
        let(:revision_sha1) { `git rev-parse HEAD`.chomp }
        let(:remote_url) { `git remote get-url $(git remote show | head -n 1)`.chomp }

        before do
          allow(JayAPI::Git::Repository).to receive(:new)
            .and_raise(Git::GitExecuteError, 'Invalid git repository')
        end

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when the test fails' do
        let(:status) { :failed }
        let(:expected_result) { 'fail' }

        let(:exception) do
          RSpec::Expectations::ExpectationNotMetError.new(
            "\nexpected nil\n     got #<String:70287492316260> => \"nil\"\n"
          )
        end

        let(:exception_message) do
          "expected nil\n     got #<String:70287492316260> => \"nil\""
        end

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when the tests are skipped (are pending)' do
        let(:status) { :pending }
        let(:expected_result) { 'skip' }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when there is an error in the tests' do
        let(:status) { :error }
        let(:expected_result) { 'error' }

        let(:exception_message) do
          "undefined method `config' for JayAPI::RSpec:Module"
        end

        let(:exception) do
          NoMethodError.new(exception_message)
        end

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when the tests end with an unknown status' do
        let(:status) { :aborted }
        let(:expected_result) { 'error' }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context 'when the test case has no requirements' do
        let(:requirements) { nil }
        let(:refs) { nil }

        let(:expected_requirements) { nil }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context "when the test case has requirements annotated with the 'requirements' key" do
        let(:requirements) { %w[ESR_REQ_7548 ESR_REQ_4923] }
        let(:refs) { nil }

        let(:expected_requirements) { %w[ESR_REQ_7548 ESR_REQ_4923] }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context "when the test case has requirements annotated with the 'refs' key" do
        let(:requirements) { nil }
        let(:refs) { %w[ESR_REQ_9498 ESR_REQ_1905] }

        let(:expected_requirements) { %w[ESR_REQ_9498 ESR_REQ_1905] }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end

      context "when the test case has requirements annotated with both the 'refs' and 'requirements' keys" do
        let(:requirements) { %w[ESR_REQ_4132 ESR_REQ_4783] }
        let(:refs) { %w[ESR_REQ_4109] }

        let(:expected_requirements) { %w[ESR_REQ_4132 ESR_REQ_4783 ESR_REQ_4109] }

        include_examples 'JayAPI::RSpec::TestDataCollector#example_finished pushes the right data to Elasticsearch'
      end
    end
  end

  describe '#close' do
    subject(:method_call) { test_data_collector.close(nil) }

    include_context 'when JayAPI::RSpec is configured'

    context 'when the data push is disabled' do
      it 'does not flush the Elasticsearch Index' do
        expect(elasticsearch_index).not_to receive(:flush)
        method_call
      end
    end

    context 'when the data push is enabled' do
      let(:push_enabled) { true }

      include_context 'when JayAPI::RSpec has Elasticsearch configuration'

      it 'flushes the Elasticsearch Index' do
        expect(elasticsearch_index).to receive(:flush)
        method_call
      end
    end
  end
end
