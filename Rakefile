# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'net/http'
require 'uri'
require 'json'

require_relative 'lib/jay_api/elasticsearch/client_factory'
require_relative 'lib/jay_api/elasticsearch/index'

CLUSTER_HOST = ENV.fetch('CLUSTER_HOST', 'localhost')
CLUSTER_URL  = "http://#{CLUSTER_HOST}"
CLUSTER_PORT = ENV.fetch('CLUSTER_PORT', '9200')

RSpec::Core::RakeTask.new(:spec)
task default: :spec

# @param [Integer] max_attempts
# @param [Integer] sleep_duration
# @raise [RuntimeError] If Elasticsearc does not respond after 'max_attempts'
def ping_elasticsearch(max_attempts: 5, sleep_duration: 5)
  url = URI.parse(CLUSTER_URL)
  max_attempts.times do |nr|
    puts "Ping nr: #{nr}..."
    begin
      return if Net::HTTP.get_response(url).is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      puts "Error while pinging Elasticsearch server: #{e.message}"
    end

    sleep sleep_duration
  end
  raise "Elasticsearch server not running or not reachable after #{max_attempts} attempts"
end

namespace :elasticsearch do
  desc 'Starts the Elasticsearch server that is needed to run End-to-End tests.'
  task :start do
    # Start docker-compose with the specified config file
    sh 'docker-compose -f ci/end-to-end/docker-compose.yml up  -d'

    # Wait for the Elasticsearch server to start
    ping_elasticsearch
  end

  desc 'Uploads the contents of all the spec/end-to-end/**/*.index files to the Elasticsearch test server.' \
       "Note: Make sure that the server is up and running before running this command (see 'start')."
  task :upload do
    # Use glob to find all *.index files in the test directory and its subdirectories
    index_files = File.join('spec/end-to-end/', '**', '*.index')

    client = JayAPI::Elasticsearch::ClientFactory.new(cluster_url: CLUSTER_URL, port: CLUSTER_PORT).create

    # Iterate through each .index file and upload it to Elasticsearch.
    Dir.glob(index_files).each do |file|
      index_name = File.basename(file).gsub('.index', '')
      puts "Uploading the contents of #{file} to index:#{index_name}, cluster: #{CLUSTER_URL}, port: #{CLUSTER_PORT}"
      index = JayAPI::Elasticsearch::Index.new(client: client, index_name: index_name)
      JSON.parse(File.read(file)).each { |document| index.push(document) }
      index.flush # Do not forget to flush the index at the end.
    end
  end

  desc "Invokes 'start' and 'upload' tasks."
  task :start_and_upload do
    Rake::Task['elasticsearch:start'].invoke
    Rake::Task['elasticsearch:upload'].invoke
  end

  desc 'Shuts down the Elasticsearch test server.'
  task :stop do
    # Stop and remove the Docker containers
    sh 'docker-compose -f ci/end-to-end/docker-compose.yml down'
  end
end

# rubocop:enable Metrics/BlockLength
