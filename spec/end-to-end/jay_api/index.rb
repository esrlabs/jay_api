# frozen_string_literal: true

require 'jay_api/elasticsearch/client_factory'
require 'jay_api/elasticsearch/index'

require_relative '../../support/array_appender'

RSpec.shared_context 'with JayAPI::Elasticsearch::Index' do
  # Required variables
  # :index_name: [String] The name of the index to use to create the +Elasticsearch::Index+ instance.

  let(:client) do
    client_factory.create
  end

  let(:array_appender) { ArrayAppender.new('array_appender') }

  let(:logger) do
    Logging.logger['end_to_end_tests_logger'].tap do |logger|
      logger.add_appenders(
        Logging.appenders.stdout,
        array_appender
      )
    end
  end

  let(:client_factory) do
    JayAPI::Elasticsearch::ClientFactory.new(
      cluster_url: "http://#{ENV.fetch('CLUSTER_HOST', 'localhost')}",
      port: ENV.fetch('CLUSTER_PORT', '9200'),
      logger: logger
    )
  end

  let(:index) do
    JayAPI::Elasticsearch::Index.new(client: client, index_name: index_name)
  end
end
