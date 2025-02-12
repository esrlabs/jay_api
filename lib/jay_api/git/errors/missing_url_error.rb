# frozen_string_literal: true

require_relative '../../errors/error'

module JayAPI
  module Git
    module Errors
      # An error to be raised when an attempt is made to execute a Git operation
      # which requires a URL without providing one.
      class MissingURLError < JayAPI::Errors::Error; end
    end
  end
end
