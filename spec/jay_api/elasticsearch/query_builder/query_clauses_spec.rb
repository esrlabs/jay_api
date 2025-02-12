# frozen_string_literal: true

require 'active_support'
require 'active_support/time_with_zone'
require 'jay_api/elasticsearch/query_builder/query_clauses'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses do
  subject(:query_clauses) { described_class.new }

  describe '#bool' do
    subject(:method_call) { query_clauses.bool }

    let(:bool_clause) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
        .to receive(:new).and_return(bool_clause)

      allow(bool_clause).to receive(:is_a?)
        .with(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
        .and_return(true)

      # The following line is needed because the ActiveSupport Helper (loaded in
      # another spec file) is hooking itself to RSpec's yield_with_args matcher
      # and is checking if the yielded value is an instance of
      # ActiveSupport::TimeWithZone.
      allow(bool_clause).to receive(:is_a?)
        .with(ActiveSupport::TimeWithZone).and_return(false)
    end

    shared_examples_for '#bool' do
      context 'when a block is given' do
        it 'yields the boolean query to the given block' do
          expect { |block| query_clauses.bool(&block) }.to yield_with_args(bool_clause)
        end

        it 'returns itself' do
          expect(query_clauses.bool {}).to eq(query_clauses)
        end
      end

      context 'when no block is given' do
        it 'returns the boolean query clause' do
          expect(method_call).to eq(bool_clause)
        end
      end
    end

    context 'when the query is not yet a boolean query' do
      it 'creates a new instance of the Boolean query clause' do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool).to receive(:new)
        method_call
      end

      it 'turns the query into a boolean query' do
        expect { method_call }.to change(query_clauses, :boolean_query?).from(false).to(true)
      end

      it_behaves_like '#bool'
    end

    context 'when the query is already a boolean query' do
      before { query_clauses.bool }

      it 'does not create a new instance of the Boolean query clause' do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool).not_to receive(:new)
        method_call
      end

      it 'does not raise any errors' do
        expect { method_call }.not_to raise_error
      end

      it_behaves_like '#bool'
    end

    context 'when there is already another type of query clause' do
      before do
        query_clauses.query_string(fields: 'field1', query: 'some value')
      end

      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
        expect { method_call }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
          'Queries can only have one top-level query clause, to use multiple ' \
          'clauses add a compound query, for example: `bool`'
        )
      end
    end
  end

  describe '#<<' do
    subject(:method_call) { query_clauses << query_clause }

    let(:query_clause) do
      instance_double(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause)
    end

    context 'when another clause has already been added' do
      before { query_clauses.wildcard(field: 'some_field', value: 'a*value') }

      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
        expect { method_call }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
          'Queries can only have one top-level query clause, to use multiple ' \
          'clauses add a compound query, for example: `bool`'
        )
      end
    end

    context 'when no other clause exists yet' do
      it 'returns self' do
        expect(method_call).to eq(query_clauses)
      end
    end
  end

  describe '#boolean_query?' do
    subject(:method_call) { query_clauses.boolean_query? }

    context 'when the query is not a boolean query' do
      it 'returns false' do
        expect(method_call).to be false
      end
    end

    context 'when the query is a boolean query' do
      before { query_clauses.bool }

      it 'returns true' do
        expect(method_call).to be true
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { query_clauses.to_h }

    context 'when the query clauses set is empty' do
      it 'returns a match-all query' do
        expect(method_call).to eq(match_all: {})
      end
    end

    context 'when the query clauses set is not empty' do
      let(:clause_hash) { {} }

      let(:query_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
          to_h: clause_hash
        )
      end

      before { query_clauses << query_clause }

      it 'calls to_h on the top-level clause' do
        expect(query_clauses).to receive(:to_h)
        method_call
      end

      it 'returns the hash returned by the top-level clause' do
        expect(method_call).to equal(clause_hash)
      end
    end
  end

  describe '#match_phrase' do
    subject(:method_call) { query_clauses.match_phrase(**params) }

    let(:params) { { field: 'some.field', phrase: 'God does not play dice!' } }

    it 'creates an instance of the MatchPhrase query clause and passes down the parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchPhrase).to receive(:new).with(**params)
      method_call
    end
  end

  describe '#match_all' do
    subject(:method_call) { query_clauses.match_all }

    it 'creates an instance of the MatchAll query clause' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchAll).to receive(:new)
      method_call
    end

    it 'returns itself' do
      expect(method_call).to be(query_clauses)
    end
  end

  describe '#match_none' do
    subject(:method_call) { query_clauses.match_none }

    it 'creates an instance of the MatchNone query clause' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone).to receive(:new)
      method_call
    end

    it 'returns itself' do
      expect(method_call).to be(query_clauses)
    end
  end

  describe '#query_string' do
    subject(:method_call) { query_clauses.query_string(**params) }

    let(:params) { { fields: 'a_field', query: 'some value' } }

    it 'creates an instance of the QueryString query clause and passes down the parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString).to receive(:new).with(**params)
      method_call
    end

    it 'returns itself' do
      expect(method_call).to eq(query_clauses)
    end
  end

  describe '#wildcard' do
    subject(:method_call) { query_clauses.wildcard(**params) }

    let(:params) { { field: 'sone_field', value: 'some string*' } }

    it 'creates an instance of the Wildcard query clause and passes down the parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Wildcard).to receive(:new).with(**params)
      method_call
    end

    it 'returns itself' do
      expect(method_call).to eq(query_clauses)
    end
  end

  describe '#empty?' do
    subject(:method_call) { query_clauses.empty? }

    context 'when the QueryClauses does not have a top-level clause' do
      it 'returns true' do
        expect(method_call).to be(true)
      end
    end

    context 'when the QueryClauses has a top-level QueryClause' do
      before { query_clauses.match_phrase(field: 'sut_revision', phrase: '24-02-15/master') }

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end
  end

  shared_examples_for '#clone' do
    it 'does not raise any errors' do
      expect { method_call }.not_to raise_error
    end

    it 'returns a copy of the receiver' do
      expect(method_call).to be_a(described_class)
      expect(method_call).not_to be(query_clauses)
    end
  end

  shared_examples_for '#clone when the receiver is empty' do
    it 'returns an empty copy' do
      expect(method_call).to be_empty
    end
  end

  shared_examples_for '#clone when the receiver is not empty' do
    let(:bool_clause_clone) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool,
        to_h: { bool: 'clause' }
      )
    end

    let(:bool_clause) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool,
        clone: bool_clause_clone,
        to_h: { bool: 'clause' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
        .to receive(:new).and_return(bool_clause)

      query_clauses.bool
    end

    it_behaves_like '#clone'

    it 'clones the enclosed QueryClause' do
      expect(bool_clause).to receive(:clone)
      method_call
    end

    it 'is not empty' do
      expect(method_call).not_to be_empty
    end

    it 'has the same Hash representation as the receiver' do
      expect(method_call.to_h).to eq(query_clauses.to_h)
    end
  end

  describe '#clone' do
    subject(:method_call) { query_clauses.clone }

    context 'when the QueryClauses does not have a top-level clause (is empty)' do
      it_behaves_like '#clone when the receiver is empty'
    end

    context 'when the QueryClauses has a top-level clause (is not empty)' do
      it_behaves_like '#clone when the receiver is not empty'
    end
  end

  describe '#merge' do
    subject(:method_call) { query_clauses.merge(other) }

    context "when 'other' is not a #{described_class}" do
      let(:other) do
        { query: { query_string: 'age: 27' } }
      end

      it 'raises a TypeError' do
        expect { method_call }.to raise_error(
          TypeError, "Cannot merge #{described_class} with Hash"
        )
      end
    end

    context "when both the receiver and 'other' are empty" do
      let(:other) { described_class.new }

      it_behaves_like '#clone when the receiver is empty'
    end

    context "when 'other' is empty but the receiver is not" do
      let(:other) { described_class.new }

      it_behaves_like '#clone when the receiver is not empty'
    end

    shared_context 'with a Range QueryClause' do
      let(:range_clause_clone) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range,
          to_h: { range: { 'build_number' => { gt: 150 } } }
        )
      end

      let(:range_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range,
          to_h: { range: { 'build_number' => { gt: 150 } } },
          clone: range_clause_clone
        )
      end

      before do
        allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Range)
          .to receive(:new).and_return(range_clause)
      end
    end

    context "when the receiver is empty but 'other' is not" do
      let(:other) { described_class.new }

      include_context 'with a Range QueryClause'

      before { other.range(field: 'build_number', gt: 150) }

      it "does not return the receiver nor 'other'" do
        expect(method_call).not_to be(query_clauses)
        expect(method_call).not_to be(other)
      end

      it "returns a copy of 'other'" do
        expect(method_call).to be_a(described_class)
        expect(method_call.to_h).to eq(other.to_h)
      end
    end

    context "when neither the receiver nor 'other' are empty" do
      let(:other) { described_class.new }

      let(:exists_clause_clone) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists,
          to_h: { exists: { field: 'build_job_name' } }
        )
      end

      let(:exists_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists,
          clone: exists_clause_clone,
          to_h: { exists: { field: 'build_job_name' } }
        )
      end

      let(:bool_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool,
          to_h: { bool: { must: [exists_clause_clone.to_h, range_clause_clone.to_h] } }
        )
      end

      let(:expected_hash) do
        {
          bool: {
            must: [
              { exists: { field: 'build_job_name' } },
              { range: { 'build_number' => { gt: 150 } } }
            ]
          }
        }
      end

      include_context 'with a Range QueryClause'

      before do
        allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Exists)
          .to receive(:new).and_return(exists_clause)

        allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool)
          .to receive(:new).and_return(bool_clause)

        allow(bool_clause).to receive(:must).and_yield(bool_clause)
        allow(bool_clause).to receive(:merge!).and_return(bool_clause)

        query_clauses.exists(field: 'build_job_name')
        other.range(field: 'build_number', gt: 150)
      end

      it 'returns a new instance of the class' do
        expect(method_call).to be_a(described_class)
      end

      it 'creates a boolean clause to merge the two enclosed clauses' do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool).to receive(:new)
        method_call
      end

      it "merges the receiver's top-level clause with the created boolean clause" do
        expect(bool_clause).to receive(:merge!).with(exists_clause)
        method_call
      end

      it "merges 'other's top-level clause with the created boolean clause" do
        expect(bool_clause).to receive(:merge!).with(range_clause)
        method_call
      end

      it 'sets the created boolean clause as top-level clause for the returned object' do
        # The #to_h call is used to make sure that the +bool_clause+ double was
        # set as top-level clause for the returned object.
        expect(method_call.to_h).to eq(expected_hash)
      end
    end
  end

  shared_context 'with a mocked MatchNone clause' do
    let(:match_none) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone,
        to_h: { match_none: {} }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone)
        .to receive(:new).and_return(match_none)
    end
  end

  shared_context 'with mocked clauses for #negate!' do
    let(:query_string) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString,
        to_h: { query_string: { query: '(new york city) OR (big apple)' } }
      )
    end

    let(:bool_clause) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool,
        to_h: { bool: { must_not: [query_string.to_h] } }
      )
    end

    let(:negator) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator,
        negate: bool_clause
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryString)
        .to receive(:new).and_return(query_string)

      query_clauses.query_string(query: '(new york city) OR (big apple)')

      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator)
        .to receive(:new).and_return(negator)
    end
  end

  shared_examples_for "negate! when the QueryClauses object doesn't have a clause" do
    it 'creates a match_none query clause' do
      expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::MatchNone).to receive(:new)
      method_call
    end

    it 'transforms the query into a match_none query' do
      expect(method_call.to_h).to eq(match_none: {})
    end
  end

  shared_examples_for 'negate! when the QueryClauses object has a clause' do
    it 'turns the QueryClause into a negated version of itself' do
      expect(method_call.to_h).to eq(
        bool: { must_not: [{ query_string: { query: '(new york city) OR (big apple)' } }] }
      )
    end
  end

  describe '#negate!' do
    subject(:method_call) { query_clauses.negate! }

    it 'returns the same object' do
      expect(method_call).to be(query_clauses)
    end

    context "when the QueryClauses object doesn't have any clauses" do
      include_context 'with a mocked MatchNone clause'

      it_behaves_like "negate! when the QueryClauses object doesn't have a clause"
    end

    context 'when the QueryClauses object has a clause' do
      include_context 'with mocked clauses for #negate!'

      it 'creates a Negator object to negate the clause' do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator)
          .to receive(:new).with(query_string)
        expect(negator).to receive(:negate)
        method_call
      end

      it_behaves_like 'negate! when the QueryClauses object has a clause'
    end
  end

  describe '#negate' do
    subject(:method_call) { query_clauses.negate }

    it 'returns an instance of the same class but does not return the same object' do
      expect(method_call).to be_a(described_class)
      expect(method_call).not_to be(query_clauses)
    end

    it 'does not change the original object' do
      expect { method_call }.not_to change(query_clauses, :to_h)
    end

    context "when the QueryClauses object doesn't have any clauses" do
      include_context 'with a mocked MatchNone clause'

      it_behaves_like "negate! when the QueryClauses object doesn't have a clause"
    end

    context 'when the QueryClauses object has a clause' do
      include_context 'with mocked clauses for #negate!'

      let(:query_string_clone) do
        query_string.clone
      end

      before do
        allow(query_string).to receive(:clone).and_return(query_string_clone)
      end

      it 'clones the top-level clause before performing the negation' do
        expect(query_string).to receive(:clone)
        method_call
      end

      it "creates a Negator object to negate the top-level clause's clone" do
        expect(JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Negator)
          .to receive(:new).with(query_string_clone)
        expect(negator).to receive(:negate)
        method_call
      end

      it_behaves_like 'negate! when the QueryClauses object has a clause'
    end
  end
end
