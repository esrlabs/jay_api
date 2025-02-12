# frozen_string_literal: true

require_relative '../../../../support/matchers/have_duration/matcher'

RSpec.describe Support::Matchers::HaveDuration::Matcher do
  describe 'timing a block execution' do
    context 'when block execution is within the expected range' do
      context 'with a very short execution time' do
        it 'passes' do
          expect { 100.times { 2 + 2 } }.to have_duration(0..0.1)
        end
      end

      context 'with a longer execution time' do
        it 'passes' do
          expect { sleep(3) }.to have_duration(2.5..3.5)
        end
      end
    end

    context 'when block execution is longer than the upper bound of the range' do
      let(:error_msg) { /expected block to execute within 1..1.5, but executed in \d+\.\d+ seconds/ }

      it 'fails for a block executing slower than the range' do
        expect do
          expect { sleep(2) }.to have_duration(1..1.5)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError, error_msg
        )
      end
    end

    context 'when block execution is quicker than the lower bound of the range' do
      let(:error_msg) { /expected block to execute within 0.5..1, but executed in \d+\.\d+ seconds/ }

      it 'fails for a block executing quicker than the range' do
        expect do
          expect { sleep(0.1) }.to have_duration(0.5..1)
        end.to raise_error(
          RSpec::Expectations::ExpectationNotMetError, error_msg
        )
      end
    end

    context 'with within.of syntax' do
      context 'when block execution is within the margin of the target time' do
        it 'passes for a block executing close to the target time' do
          expect { sleep(1.1) }.to have_duration(within(0.2).of(1))
        end
      end

      context 'when block execution is outside the margin of the target time' do
        let(:error_msg) { /expected block to execute within 0.4 of 1, but executed in \d+\.\d+ seconds/ }

        it 'fails for a block executing too far from the target time' do
          expect do
            expect { sleep(1.5) }.to have_duration(within(0.4).of(1))
          end.to raise_error(
            RSpec::Expectations::ExpectationNotMetError, error_msg
          )
        end
      end
    end
  end
end
