# frozen_string_literal: true

module JayAPI
  module Git
    module Errors
      # An error to be raised when an attempt is made to perform an action on a
      # repository that is not yet initialized.
      class InvalidRepositoryError < StandardError; end
    end
  end
end
