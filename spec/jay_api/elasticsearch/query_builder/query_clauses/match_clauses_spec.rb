# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/match_clauses'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchClauses do
  subject(:test_instance) { test_class.new }

  let(:test_class) do
    Class.new(Array) do
      include JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchClauses
    end
  end

  shared_examples_for '#match_phrase' do
    let(:clause_instance) { instance_double(clause_class) }

    before do
      allow(clause_class).to receive(:new).and_return(clause_instance)
    end

    it 'creates a new instance of the query clause with the expected parameters' do
      expect(clause_class).to receive(:new).with(params)
      method_call
    end

    it 'adds the newly created instance to the query clauses set' do
      method_call
      expect(test_instance).to include(clause_instance)
    end
  end

  describe '#match_phrase' do
    subject(:method_call) { test_instance.match_phrase(**params) }

    let(:params) { { field: 'text', phrase: 'The quick brown fox' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase }

    it_behaves_like '#match_phrase'
  end

  describe '#query_string' do
    subject(:method_call) { test_instance.query_string(**params) }

    let(:params) { { query: 'build_job_name: *master* AND build_number: 105' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString }

    it_behaves_like '#match_phrase'
  end

  describe '#wildcard' do
    subject(:method_call) { test_instance.wildcard(**params) }

    let(:params) { { field: 'test_case.name', value: 'Networking/CAN0?/From CAN0? TO CAN-FD*' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard }

    it_behaves_like '#match_phrase'
  end

  describe '#exists' do
    subject(:method_call) { test_instance.exists(**params) }

    let(:params) { { field: 'test_env.node_name' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists }

    it_behaves_like '#match_phrase'
  end

  describe '#term' do
    subject(:method_call) { test_instance.term(**params) }

    let(:params) { { field: 'test_env.build_job_name.keyword', value: 'release-master' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Term }

    it_behaves_like '#match_phrase'
  end

  describe '#range' do
    subject(:method_call) { test_instance.range(**params) }

    let(:params) { { field: 'test_env.build_number', gt: 100, lte: 200 } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range }

    it_behaves_like '#match_phrase'
  end

  describe '#terms' do
    subject(:method_call) { test_instance.terms(**params) }

    let(:params) { { field: 'test_case.result', terms: %w[pass skip] } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms }

    it_behaves_like '#match_phrase'
  end

  describe '#regexp' do
    subject(:method_call) { test_instance.regexp(**params) }

    let(:params) { { field: 'sut_revision.keyword', value: '[0-9]{2}-[0-9]{2}-[0-9]{2}/.*' } }

    let(:clause_class) { JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Regexp }

    it_behaves_like '#match_phrase'
  end
end
