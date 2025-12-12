# frozen_string_literal: true

require 'jay_api/properties_fetcher'
require 'jay_api/errors/configuration_error'
require 'jay_api/elasticsearch/index'
require 'jay_api/elasticsearch/query_results'
require 'jay_api/elasticsearch/query_builder'

RSpec.describe JayAPI::PropertiesFetcher do
  subject(:properties_fetcher) { described_class.new(index: index) }

  let(:records) do
    [
      { some: 'properties' },
      { other: 'properties' },
      { last: 'properties' }
    ]
  end

  let(:query_results) do
    instance_double(
      JayAPI::Elasticsearch::QueryResults,
      first: records.first,
      last: records.last,
      all: records.each
    )
  end

  let(:index) do
    instance_double(
      JayAPI::Elasticsearch::Index,
      search: query_results
    )
  end

  let(:bool_clause) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool
    )
  end

  let(:query_clauses) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::QueryClauses,
      bool: bool_clause
    )
  end

  let(:query_hash) { { some: 'query' } }

  let(:query_builder) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder,
      query: query_clauses,
      to_query: query_hash
    )
  end

  before do
    allow(JayAPI::Elasticsearch::QueryBuilder).to receive(:new).and_return(query_builder)
    allow(query_builder).to receive(:sort).and_return(query_builder)
    allow(query_builder).to receive(:size).and_return(query_builder)

    allow(query_clauses).to receive(:query_string).and_return(query_clauses)
    allow(bool_clause).to receive(:must).and_return(bool_clause)
    allow(bool_clause).to receive(:query_string).and_return(bool_clause)
    allow(bool_clause).to receive(:match_phrase).and_return(bool_clause)
  end

  shared_examples 'creates an instance of the QueryBuilder class' do
    it 'creates an instance of the QueryBuilder class' do
      expect(JayAPI::Elasticsearch::QueryBuilder).to receive(:new)
      method_call
    end
  end

  shared_examples 'does not create a new instance of the QueryBuilder class' do
    it 'does not create an instance of the QueryBuilder class' do
      expect(JayAPI::Elasticsearch::QueryBuilder).not_to receive(:new)
      method_call
    end
  end

  shared_examples 'creates a boolean query' do
    it 'creates a boolean query' do
      expect(query_clauses).to receive(:bool)
      expect(bool_clause).to receive(:must)
      method_call
    end
  end

  shared_examples 'adds the expected QueryString Clause to the boolean query' do
    it 'adds the expected QueryClause to the boolean query' do
      expect(bool_clause).to receive(:query_string)
        .with(fields: fields, query: expected_query)

      method_call
    end
  end

  shared_examples 'adds the expected MatchPhrase Clause to the boolean query' do
    it 'adds the expected QueryClause to the boolean query' do
      expect(bool_clause).to receive(:match_phrase)
        .with(field: field, phrase: expected_phrase)

      method_call
    end
  end

  shared_examples 'returns itself' do
    it 'returns itself' do
      expect(method_call).to eq(properties_fetcher)
    end
  end

  shared_examples 'executes the query against Elasticsearch' do
    it 'calls to_query on the QueryBuilder to create the query' do
      expect(query_builder).to receive(:to_query)
      method_call
    end

    it 'executes the constructed query to search the Elasticsearch index' do
      expect(index).to receive(:search).with(query_hash)
      method_call
    end
  end

  shared_examples 'resets the QueryComposer object' do
    describe 'query reset' do
      # When another method is called a new QueryBuilder is created

      before { method_call }

      it 'resets the Query Builder after the call' do
        expect(JayAPI::Elasticsearch::QueryBuilder).to receive(:new)
        properties_fetcher.by_software_version('X310')
      end
    end
  end

  describe '#by_build_job' do
    subject(:method_call) { properties_fetcher.by_build_job(build_job) }

    let(:build_job) { 'Release-XYZ01-Master' }
    let(:field) { 'build_properties.build_name.keyword' }
    let(:expected_phrase) { build_job }

    shared_examples_for '#by_build_job' do
      include_examples 'creates a boolean query'
      include_examples 'adds the expected MatchPhrase Clause to the boolean query'
      include_examples 'returns itself'
    end

    context 'when no other method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#by_build_job'
    end

    context 'when another method has already been called' do
      before { properties_fetcher.by_build_number(123) }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#by_build_job'
    end
  end

  describe '#by_sut_revision' do
    subject(:method_call) { properties_fetcher.by_sut_revision(sut_revision) }

    let(:sut_revision) { 'Release/Master' }
    let(:field) { 'sut_revision.keyword' }
    let(:expected_phrase) { sut_revision }

    shared_examples_for '#by_sut_revision' do
      include_examples 'creates a boolean query'
      include_examples 'adds the expected MatchPhrase Clause to the boolean query'
      include_examples 'returns itself'
    end

    context 'when no other method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#by_sut_revision'
    end

    context 'when another method has already been called' do
      before { properties_fetcher.by_build_number(123) }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#by_sut_revision'
    end
  end

  describe '#by_build_number' do
    subject(:method_call) { properties_fetcher.by_build_number(build_number) }

    let(:build_number) { 303 }
    let(:fields) { 'build_properties.build_number' }
    let(:expected_query) { build_number }

    shared_examples_for '#by_build_number' do
      include_examples 'creates a boolean query'
      include_examples 'adds the expected QueryString Clause to the boolean query'
      include_examples 'returns itself'
    end

    context 'when no other method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#by_build_number'
    end

    context 'when another method has already been called' do
      before { properties_fetcher.by_build_job('Release-XYZ01-Debug') }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#by_build_number'
    end
  end

  describe '#by_software_version' do
    subject(:method_call) { properties_fetcher.by_software_version(software_version) }

    let(:software_version) { 'H410' }
    let(:field) { 'build_properties.version_code.keyword' }
    let(:expected_phrase) { software_version }

    shared_examples_for '#by_software_version' do
      include_examples 'creates a boolean query'
      include_examples 'adds the expected MatchPhrase Clause to the boolean query'
      include_examples 'returns itself'
    end

    context 'when no other methods have been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#by_software_version'
    end

    context 'when another method has been called before' do
      before { properties_fetcher.by_release_tag(true) }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#by_software_version'
    end
  end

  describe '#by_release_tag' do
    subject(:method_call) { properties_fetcher.by_release_tag(release_tag) }

    let(:release_tag) { true }
    let(:fields) { 'build_properties.build_release' }
    let(:expected_query) { release_tag }

    shared_examples_for '#by_release_tag' do
      include_examples 'creates a boolean query'
      include_examples 'adds the expected QueryString Clause to the boolean query'
      include_examples 'returns itself'
    end

    context 'when no other methods have been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#by_release_tag'
    end

    context 'when another method has been called before' do
      before { properties_fetcher.by_build_job('Release-XYZ01-Master') }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#by_release_tag'
    end
  end

  shared_examples_for '#after and #before' do
    let(:fields) { 'timestamp' }

    shared_examples_for '#after' do
      include_examples 'creates a boolean query'

      context 'when the given timestamp is a Time object' do
        let(:expected_query) { expected_query_for_time }

        include_examples 'adds the expected QueryString Clause to the boolean query'
      end

      context 'when the given timestamp is a String' do
        let(:expected_query) { expected_query_for_string }
        let(:timestamp) { '2022/05/05 16:27:31' }

        include_examples 'adds the expected QueryString Clause to the boolean query'
      end

      include_examples 'returns itself'
    end

    context 'when no other methods have been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#after'
    end

    context 'when another method has been called before' do
      before { properties_fetcher.by_build_job('Release-XYZ01-Master') }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#after'
    end
  end

  describe '#after' do
    subject(:method_call) { properties_fetcher.after(timestamp) }

    let(:timestamp) { Time.new(2022, 3, 3, 6, 15, 45, '+09:00') }

    let(:expected_query_for_time) { '> "2022/03/02 21:15:45"' } # Performs UTC conversion
    let(:expected_query_for_string) { '> "2022/05/05 16:27:31"' }

    it_behaves_like '#after and #before'
  end

  describe '#before' do
    subject(:method_call) { properties_fetcher.before(timestamp) }

    let(:timestamp) { Time.new(2022, 3, 3, 6, 15, 45, '+09:00') }
    let(:expected_query_for_time) { '< "2022/03/02 21:15:45"' } # Performs UTC conversion
    let(:expected_query_for_string) { '< "2022/05/05 16:27:31"' }

    it_behaves_like '#after and #before'
  end

  describe '#and' do
    subject(:method_call) { properties_fetcher.and }

    include_examples 'returns itself'
  end

  describe '#last' do
    subject(:method_call) { properties_fetcher.last }

    shared_examples_for '#last' do
      it 'adds a sorting clause to the query' do
        expect(query_builder).to receive(:sort).with('timestamp' => 'desc')
        method_call
      end

      it 'adds a size clause to the query (to fetch only one record)' do
        expect(query_builder).to receive(:size).with(1)
        method_call
      end
    end

    context 'when no method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#last'
    end

    context 'when another method has already been called' do
      before { properties_fetcher.by_build_number(836) }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#last'
    end

    include_examples 'executes the query against Elasticsearch'

    include_examples 'resets the QueryComposer object'

    context 'when records are found' do
      it 'returns the last document from the QueryResult object' do
        expect(method_call).to eq(records.last)
      end
    end

    context 'when no records are found' do
      let(:records) { [] }

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end
  end

  describe '#first' do
    subject(:method_call) { properties_fetcher.first }

    shared_examples_for '#first' do
      it 'adds a sorting clause to the query' do
        expect(query_builder).to receive(:sort).with('timestamp' => 'asc')
        method_call
      end

      it 'adds a size clause to the query (to fetch only one record)' do
        expect(query_builder).to receive(:size).with(1)
        method_call
      end
    end

    context 'when no method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#first'
    end

    context 'when another method has already been called' do
      before { properties_fetcher.by_release_tag(false) }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#first'
    end

    include_examples 'executes the query against Elasticsearch'

    include_examples 'resets the QueryComposer object'

    context 'when records are found' do
      it 'returns the first document from the QueryResult object' do
        expect(method_call).to eq(records.first)
      end
    end

    context 'when no records are found' do
      let(:records) { [] }

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end
  end

  shared_examples_for '#limit' do
    shared_examples_for '#limit when it adds the limit clause to the query' do
      context 'when the given limit is less than or equal to the maximum' do
        it 'adds a limit clause with the given limit to the query builder' do
          expect(query_builder).to receive(:size).with(used_size)
          method_call
        end
      end

      context 'when the given limit is greater than the maximum' do
        let(:size) { 500 }
        let(:used_size) { described_class::MAX_SIZE }

        it 'adds a limit clause with the maximum limit to the query builder' do
          expect(query_builder).to receive(:size).with(used_size)
          method_call
        end
      end

      include_examples 'returns itself'
    end

    context 'when no method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#limit when it adds the limit clause to the query'
    end

    context 'when another method has been called before' do
      before { properties_fetcher.by_build_job('Release-XYZ01-Master') }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#limit when it adds the limit clause to the query'
    end
  end

  describe '#limit' do
    subject(:method_call) { properties_fetcher.limit(size) }

    let(:size) { 10 }
    let(:used_size) { size }

    it_behaves_like '#limit'
  end

  describe '#size' do
    subject(:method_call) { properties_fetcher.size(size) }

    let(:size) { 25 }
    let(:used_size) { size }

    it_behaves_like '#limit'
  end

  describe '#all' do
    subject(:method_call) { properties_fetcher.all(&block) }

    let(:block) { nil }

    shared_examples_for '#all' do
      include_examples 'executes the query against Elasticsearch'

      include_examples 'resets the QueryComposer object'

      context 'when no block is given' do
        it 'calls #all on the query_results object without a block' do
          expect(query_results).to receive(:all) do |&block|
            expect(block).to be_nil
          end

          method_call
        end

        it 'returns an Enumerator for the query results' do
          expect(method_call).to be_an(Enumerator)
          expect(method_call.to_a).to eq(records)
        end
      end

      context 'when a block is given' do
        let(:block) { proc { |_record| } }

        # This is needed to get around the parameter name collision
        let(:passed_block) { block }

        it 'calls #all on the query_results and passes down the block' do
          expect(query_results).to receive(:all) do |&block|
            expect(block).to be(passed_block)
          end

          method_call
        end
      end
    end

    context 'when no method has been called before' do
      include_examples 'creates an instance of the QueryBuilder class'

      it_behaves_like '#all'
    end

    context 'when a method has been called before' do
      before { properties_fetcher.by_build_job('Release-XYZ01-Master') }

      include_examples 'does not create a new instance of the QueryBuilder class'

      it_behaves_like '#all'
    end
  end
end
