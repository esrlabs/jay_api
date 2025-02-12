# frozen_string_literal: true

require 'jay_api/properties_fetcher'

require_relative 'index'

RSpec.describe JayAPI::PropertiesFetcher do
  subject(:properties_fetcher) { described_class.new(index: index) }

  include_context 'with JayAPI::Elasticsearch::Index'

  describe '#all' do
    describe "index 'build_properties_by_build_job'" do
      let(:index_name) { 'properties_fetcher_by_build_job' }
      let(:nr_of_docs) { 3 }

      it 'returns all of the Docs in an index' do
        expect(properties_fetcher.all.size).to be(nr_of_docs)
      end
    end

    describe "index 'properties_fetcher_by_sut_revision'" do
      let(:index_name) { 'properties_fetcher_by_sut_revision' }
      let(:nr_of_docs) { 4 }

      it 'returns all of the Docs in an index' do
        expect(properties_fetcher.all.size).to be(nr_of_docs)
      end
    end
  end

  shared_examples_for '#by_<some_query>' do
    it 'returns a QueryResults object with the expected number of Documents' do
      expect(method_call.all.size).to be(nr_of_docs)
    end

    it 'returns only the documents that match the queried attribute' do
      method_call.all do |doc|
        expect(doc).to include(doc_format)
      end
    end
  end

  describe '#by_build_job' do
    subject(:method_call) { properties_fetcher.by_build_job(build_job) }

    let(:index_name) { 'properties_fetcher_by_build_job' }

    context 'when specifying the build job name' do
      # rubocop: disable Layout/FirstHashElementIndentation
      let(:doc_format) do
        {
          '_source' => include({
            'build_properties' => include({
              'build_name' => build_job
            })
          })
        }
      end
      # rubocop: enable Layout/FirstHashElementIndentation

      describe 'SOME-RELEASE-BUILD' do
        let(:build_job) { 'SOME-RELEASE-BUILD' }
        let(:nr_of_docs) { 2 }

        it_behaves_like '#by_<some_query>'
      end

      describe 'ANOTHER-JOB-NAME' do
        let(:build_job) { 'ANOTHER-JOB-NAME' }
        let(:nr_of_docs) { 1 }

        it_behaves_like '#by_<some_query>'
      end
    end
  end

  describe '#by_sut_revision' do
    subject(:method_call) { properties_fetcher.by_sut_revision(sut_revision) }

    let(:index_name) { 'properties_fetcher_by_sut_revision' }

    let(:doc_format) do
      {
        '_source' => include(
          'sut_revision' => sut_revision
        )
      }
    end

    context 'when specifying the sut_revision' do
      describe '23-08-02/master' do
        let(:sut_revision) { '23-08-02/master' }
        let(:nr_of_docs) { 3 }

        it_behaves_like '#by_<some_query>'
      end

      describe '22-01-01/another_branch' do
        let(:sut_revision) { '22-01-01/another_branch' }
        let(:nr_of_docs) { 1 }

        it_behaves_like '#by_<some_query>'
      end
    end
  end
end
