# frozen_string_literal: true

module JayAPI
  module Abstract
    # A class for an abstract 'Connection'. It is responsible for yielding a block
    # for +max_attempts+ times at most, or until a specified +error+ is no longer
    # raised. The reason the class is specifically called 'Connection', is because
    # it contains logging that describes a connection.
    class Connection
      attr_reader :attempts, :max_attempts, :wait_strategy, :logger

      # @param [Integer] max_attempts The maximum number of connection attempts to be made.
      # @param [JayAPI::Elasticsearch::WaitStrategy] wait_strategy The waiting strategy for reconnections.
      # @param [Logging::Logger] logger
      def initialize(max_attempts:, wait_strategy:, logger:)
        @max_attempts = max_attempts
        @wait_strategy = wait_strategy
        @logger = logger
        @attempts = 0
      end

      # Yields the passed block and if the specified 'error' is raised, a new
      # yield attempt will be made until the +max_attempts+ limit is reached.
      # @param [Class, Array<Class>] errors Some error Class, or a list of them.
      # @param [Array<Class>] except An array of exceptions for which no retry
      #   should happen even if they are subclasses of the exception(s) passed
      #   in +errors+.
      def retry(errors:, except: [])
        self.attempts += 1
        yield
      rescue *errors => e
        raise if except.any? { |exception| e.is_a?(exception) }

        logger.info("#{e} occurred")
        if attempts < max_attempts
          wait_strategy.wait
          logger.info("Retrying... (There are #{max_attempts - attempts} retries left)")
          retry
        end

        logger.info('No more attempts to connect will be made')
        raise
      end

      private

      attr_writer :attempts
    end
  end
end
