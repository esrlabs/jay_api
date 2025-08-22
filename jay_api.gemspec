# frozen_string_literal: true

require_relative 'lib/jay_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'jay_api'
  spec.version       = JayAPI::VERSION
  spec.authors       = ['Accenture-Industry X', 'ESR Labs']

  spec.summary       = "A collection of classes and modules to access JAY's functionality"
  spec.description   = "A collection of classes and modules to access JAY's functionality"
  spec.homepage      = 'https://github.com/esrlabs/jay_api'
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/esrlabs/jay_api/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(CHANGELOG|README|lib/)}) } << File.basename(__FILE__)
  end

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 7'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1'
  spec.add_runtime_dependency 'elasticsearch', '~> 7', '<= 7.9.0'
  spec.add_runtime_dependency 'git', '~> 1', '>= 1.8.0-1'
  spec.add_runtime_dependency 'logging', '~> 2'
  spec.add_runtime_dependency 'rspec', '~> 3.0'
end
