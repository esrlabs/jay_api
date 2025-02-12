# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string'
require 'digest'
require 'securerandom'

module JayAPI
  # Provides methods to calculate special identifiers for Test Case for Jay.
  class IDBuilder
    attr_reader :test_case_id, :project, :software_version, :result

    def initialize(test_case_id: nil, project: nil, software_version: nil, result: nil)
      @test_case_id = test_case_id
      @project = project
      @software_version = software_version
      @result = result
    end

    # @return [String] The Sort ID for the Test Case (composed from the
    #   Project's name and a clean version of the full Test Case Identifier)
    # noinspection RubyNilAnalysis
    def short_id
      unless test_case_id && project
        raise ArgumentError,
              "The Test Case ID (test_case_id) and the Project's name " \
              '(project) are required to calculate the Short ID'
      end

      clean_id = test_case_id.downcase.gsub(/[^a-z0-9-]/, '')
      "#{project.underscore}_#{Digest::SHA1.new.update(clean_id).hexdigest[0...12]}"
    end

    # @return [Array] An array with two elements:
    #  - The secure Seed (A Version 4 UUID)
    #  - The secure Hash composed by concatenating the Software Version, the
    #    secure Seed and the result of the Test Case.
    #  This Secure ID is meant for end-to-end verification of the test results.
    def secure_id
      unless software_version && result
        raise ArgumentError,
              'The Software Version (software_version) and the Result ' \
              '(result) are required to calculate the Secure ID'
      end

      [
        uuid = SecureRandom.uuid,
        Digest::MD5.hexdigest("#{software_version}:#{uuid}:#{result}")
      ]
    end
  end
end
