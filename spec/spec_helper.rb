require "bundler/setup"

if ENV.fetch('COVERAGE', 'false') == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
    enable_coverage :branch
  end
end

require "jay_api"
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Run the tests in random order to ensure no tests dependencies
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
