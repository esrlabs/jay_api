# frozen_string_literal: true

require 'jay_api/abstract/connection'
require 'jay_api/abstract/wait_strategy'

RSpec.describe JayAPI::Abstract::Connection do
  subject(:connection) { described_class.new(max_attempts: max_attempts, wait_strategy: wait_strategy, logger: logger) }

  let(:max_attempts) { 3 }
  let(:wait_strategy) { instance_double(JayAPI::Abstract::WaitStrategy, wait: nil) }
  # rubocop:disable RSpec/VerifiedDoubles (Cannot be used because of meta-programming)
  let(:logger) { double(Logging::Logger, info: nil) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:errors) { [StandardError, SecurityError] }

  describe '#retry' do
    subject(:method_call) { connection.retry(errors: errors, &input_proc) }

    context 'when block executes without errors' do
      let(:input_proc) do
        proc do
          'success'
        end
      end

      it 'does not wait' do
        expect(wait_strategy).not_to receive(:wait)

        method_call
      end

      it 'returns the block result' do
        expect(method_call).to eq('success')
      end
    end

    shared_examples_for '#retry when the maximum attempts are not exceeded' do
      let(:input_proc) do
        proc do
          raise exception_to_raise if connection.attempts < max_attempts

          'recovered'
        end
      end

      it 'returns the block result' do
        expect(method_call).to eq('recovered')
      end

      it 'retries until max_attempts is reached' do
        method_call

        expect(connection.attempts).to eq(max_attempts)
      end

      it 'logs each error occurrence' do
        (1..max_attempts - 1).to_a.reverse.each do |time|
          expect(logger).to receive(:info).with("Retrying... (There are #{time} retries left)").ordered
        end

        method_call
      end

      it 'calls the wait strategy before each retry' do
        expect(wait_strategy).to receive(:wait).exactly(max_attempts - 1).times

        method_call
      end
    end

    shared_examples_for '#retry when the maximum attempts are exceeded' do
      let(:input_proc) do
        proc do
          raise exception_to_raise, 'some specific error'
        end
      end

      it 'raises the last error' do
        expect { method_call }.to raise_error(exception_to_raise)
      end

      it 'retries until max_attempts is reached' do
        expect { method_call }.to raise_error(exception_to_raise, 'some specific error')

        expect(connection.attempts).to eq(max_attempts)
      end

      # rubocop: disable RSpec/MultipleExpectations - Necessary to verify ordered sequential logging behavior
      it 'logs each error occurrence' do
        (1..max_attempts - 1).to_a.reverse.each do |time|
          expect(logger).to receive(:info).with("Retrying... (There are #{time} retries left)").ordered
        end
        expect(logger).to receive(:info).with('No more attempts to connect will be made').ordered

        expect { method_call }.to raise_error(exception_to_raise, 'some specific error')
      end
      # rubocop: enable RSpec/MultipleExpectations

      it 'calls the wait strategy before each retry' do
        expect(wait_strategy).to receive(:wait).exactly(max_attempts - 1).times

        expect { method_call }.to raise_error(exception_to_raise, 'some specific error')
      end
    end

    shared_examples_for '#retry when an unexpected error is raised' do
      let(:input_proc) do
        proc do
          raise exception_to_raise, 'the one off'
        end
      end

      it 'does not retry' do
        expect { method_call }.to raise_error(exception_to_raise, 'the one off')
        expect(connection.attempts).to eq(1)
      end

      it 'raises the error' do
        expect { method_call }.to raise_error(exception_to_raise, 'the one off')
      end
    end

    context 'when an error occurs' do
      context 'when the max attempts are not exceeded' do
        let(:exception_to_raise) { StandardError }

        it_behaves_like '#retry when the maximum attempts are not exceeded'
      end

      context 'when max_attempts are exceeded' do
        let(:exception_to_raise) { SecurityError }

        it_behaves_like '#retry when the maximum attempts are exceeded'
      end

      context 'when the raised error is not one of the known errors' do
        let(:exception_to_raise) { NoMemoryError }

        it_behaves_like '#retry when an unexpected error is raised'
      end
    end

    context 'when exceptions are set' do
      subject(:method_call) { connection.retry(errors: errors, except: [ArgumentError, RegexpError], &input_proc) }

      context 'when the raised_error is one of the exceptions' do
        let(:exception_to_raise) { ArgumentError }

        it_behaves_like '#retry when an unexpected error is raised'
      end

      context 'when the raised error is not one of the exceptions' do
        let(:exception_to_raise) { KeyError }

        context 'when the max attempts are not exceeded' do
          include_examples '#retry when the maximum attempts are not exceeded'
        end

        context 'when max_attempts are exceeded' do
          include_examples '#retry when the maximum attempts are exceeded'
        end
      end

      context 'when the raised error is not one of the known errors' do
        let(:exception_to_raise) { NoMemoryError }

        it_behaves_like '#retry when an unexpected error is raised'
      end
    end
  end
end
