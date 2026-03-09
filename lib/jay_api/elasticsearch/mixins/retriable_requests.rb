# frozen_string_literal: true

require 'elasticsearch/transport/transport/errors'

require_relative '../../abstract/connection'

module JayAPI
  module Elasticsearch
    module Mixins
      # A mixin that allows the including class to retry requests to
      # Elasticsearch by leveraging the +Abstract::Connection+ class'
      # capabilities.
      module RetriableRequests
        # The errors that, if raised, must cause a retry of the connection.
        RETRIABLE_ERRORS = [
          ::Elasticsearch::Transport::Transport::ServerError,
          Faraday::TimeoutError
        ].freeze

        # Subclasses of the +Elasticsearch::Transport::Transport::ServerError+
        # for which a retry doesn't make sense.
        NON_RETRIABLE_ERRORS = [
          ::Elasticsearch::Transport::Transport::Errors::BadRequest,
          ::Elasticsearch::Transport::Transport::Errors::Unauthorized,
          ::Elasticsearch::Transport::Transport::Errors::Forbidden,
          ::Elasticsearch::Transport::Transport::Errors::NotFound,
          ::Elasticsearch::Transport::Transport::Errors::MethodNotAllowed,
          ::Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge,
          ::Elasticsearch::Transport::Transport::Errors::NotImplemented
        ].freeze

        # @return [Integer] The maximum number of times a request should be
        #   retried before giving up.
        def max_attempts
          raise_not_implemented(__method__)
        end

        # @return [JayAPI::Elasticsearch::WaitStrategy] The waiting strategy for
        #   retries.
        def wait_strategy
          raise_not_implemented(__method__)
        end

        # @return [Logging::Logger] A logger to log messages.
        def logger
          raise_not_implemented(__method__)
        end

        # @return [Array<Class>] The array of errors that, if raised, must cause
        #   a retry of the request.
        def retriable_errors
          RETRIABLE_ERRORS
        end

        # @return [Array<Class>] An array of subclasses of the
        #   +Elasticsearch::Transport::Transport::ServerError+ for which a retry
        #   doesn't make sense.
        def non_retriable_errors
          NON_RETRIABLE_ERRORS
        end

        private

        # Uses the +Abstract::Connection+ class to retry the request enclosed in
        #   the given block.
        def retry_request(&)
          Abstract::Connection.new(max_attempts:, wait_strategy: wait_strategy.dup, logger:)
                              .retry(errors: retriable_errors, except: non_retriable_errors, &)
        end

        # @raise [NotImplementedError] Is always raised with the appropriate
        #   error message.
        def raise_not_implemented(method)
          raise NotImplementedError, "Please implement the method ##{method} in #{self.class}"
        end
      end
    end
  end
end
