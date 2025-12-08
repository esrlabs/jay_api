# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder'

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder#to_query' do
  context 'when no from clause has been added' do
    it 'does not include a :from key' do
      expect(method_call).not_to include(:from)
    end
  end

  context 'when a from clause has been added' do
    before { query_builder.from(10) }

    it 'includes the expected :from key' do
      expect(method_call).to include(from: 10)
    end
  end

  context 'when no size clause has been added' do
    it 'does not include the :size key' do
      expect(method_call).not_to include(:size)
    end
  end

  context 'when a size clause has been added' do
    before { query_builder.size(150) }

    it 'includes the expected :size key' do
      expect(method_call).to include(size: 150)
    end
  end

  context 'when no source clause has been added' do
    it 'does not include the :_source key' do
      expect(method_call).not_to include(:_source)
    end
  end

  context 'when a source clause has been added' do
    before { query_builder.source('test_case.*') }

    it 'inclues the expected :_source key' do
      expect(method_call).to include(_source: 'test_case.*')
    end
  end

  it 'gets the query hash from the QueryClauses instance' do
    expect(query_clauses).to receive(:to_h)
    method_call
  end

  it 'adds the returned query hash to the query' do
    expect(method_call).to include(query: query_clauses_hash)
  end

  context 'when no sorting has been set' do
    it "doesn't add the :sort key" do
      expect(method_call).not_to include(:sort)
    end
  end

  context 'when sorting has been set' do
    context 'when only one sort field has been given' do
      before { query_builder.sort(name: :asc) }

      it 'adds the :sort key with the expected content' do
        expect(method_call).to include(sort: [{ name: { order: :asc } }])
      end
    end

    context 'when multiple sort fields have been given' do
      shared_examples_for '#to_query with multiple sort fields' do
        let(:expected_sorting) do
          [
            { name: { order: :asc } },
            { age: { order: :desc } }
          ]
        end

        it 'adds the :sort key with the expected content' do
          expect(method_call).to include(sort: expected_sorting)
        end
      end

      context 'when both sort fields were given in a single call' do
        before { query_builder.sort(name: :asc, age: :desc) }

        it_behaves_like '#to_query with multiple sort fields'
      end

      context 'when each sort field was given in its own call' do
        before do
          query_builder.sort(name: :asc)
          query_builder.sort(age: :desc)
        end

        it_behaves_like '#to_query with multiple sort fields'
      end
    end

    context 'when sorting options have been given' do
      before { query_builder.sort(price: { order: :desc, missing: '_last' }) }

      it 'adds the :sort key with the expected content' do
        expect(method_call).to include(sort: [{ price: { order: :desc, missing: '_last' } }])
      end
    end

    context 'when multiple fields with sort options have been given' do
      before do
        query_builder.sort(price: { order: :desc, missing: '_last' })
        query_builder.sort(updated_at: { order: :desc, unmapped_type: 'date' })
      end

      let(:expected_sort_clause) do
        {
          sort: [
            { price: { order: :desc, missing: '_last' } },
            { updated_at: { order: :desc, unmapped_type: 'date' } }
          ]
        }
      end

      it 'adds the :sort key with the expected content' do
        expect(method_call).to include(expected_sort_clause)
      end
    end
  end

  context 'when no collapse clause has been given' do
    it 'does not include the :collapse key' do
      expect(method_call).not_to include(:collapse)
    end
  end

  context 'when a collapse clause has been added' do
    before { query_builder.collapse('department') }

    let(:expected_clause) do
      { field: 'department' }
    end

    it 'includes the expected :collapse clause' do
      expect(method_call).to include(collapse: expected_clause)
    end
  end

  context 'when there are no aggregations' do
    it 'does not include the :aggs key' do
      # noinspection SpellCheckingInspection
      expect(method_call).not_to include(:aggs)
    end
  end

  context 'when there are aggregations' do
    let(:aggregations_hash) do
      {
        aggs: {
          jobs: {
            terms: { field: 'test_env.Job Name.keyword' }
          }
        }
      }
    end

    it 'returns the expected query' do
      expect(method_call).to include(aggregations_hash)
    end
  end
end

RSpec.describe JayAPI::Elasticsearch::QueryBuilder do
  subject(:query_builder) { described_class.new }

  let(:aggregations_hash) { {} }

  let(:aggregations) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::Aggregations,
      to_h: aggregations_hash
    )
  end

  let(:query_clauses_hash) do
    { match_all: {} }
  end

  let(:bool_clause) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool
    )
  end

  let(:query_clauses) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::QueryClauses,
      bool: bool_clause,
      to_h: query_clauses_hash
    )
  end

  before do
    allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations)
      .to receive(:new).and_return(aggregations)

    allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses)
      .to receive(:new).and_return(query_clauses)
  end

  describe '#from' do
    it 'returns itself' do
      expect(query_builder.from(0)).to eq(query_builder)
    end

    context 'with a value which is not an Integer' do
      it 'raises an ArgumentError' do
        expect { query_builder.from 'five' }
          .to raise_error(
            ArgumentError,
            'Expected `from` to be one of: Integer but String was given'
          )
      end
    end

    context 'with a negative Integer' do
      it 'raises an ArgumentError' do
        expect { query_builder.from(-5) }
          .to raise_error(
            ArgumentError,
            '`from` should be a positive integer'
          )
      end
    end
  end

  describe '#source' do
    subject(:method_call) { query_builder.source(filter_expr) }

    let(:filter_expr) { 'obj.*' }

    context 'when filter_expr is not one of the allowed types' do
      let(:filter_expr) { 3 + 7i }

      it 'raises an ArgumentError' do
        expect { method_call }
          .to raise_error(
            ArgumentError,
            'Expected `source` to be one of: FalseClass, String, Array, Hash but Complex was given'
          )
      end
    end

    context 'when filter_expr is false' do
      let(:filter_expr) { false }

      let(:expected_query) do
        {
          query: { match_all: {} },
          _source: false
        }
      end

      it 'produces the expected query' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when filter_expr is a string' do
      let(:filter_expr) { 'obj.*' }

      let(:expected_query) do
        {
          query: { match_all: {} },
          _source: 'obj.*'
        }
      end

      it 'produces the expected query' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when filter_expr is an array' do
      let(:filter_expr) { %w[obj1.* obj2.*] }

      let(:expected_query) do
        {
          query: { match_all: {} },
          _source: %w[obj1.* obj2.*]
        }
      end

      it 'produces the expected query' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when filter_expr is a hash' do
      let(:filter_expr) do
        {
          includes: %w[obj1.* obj2.*],
          excludes: %w[*.description]
        }
      end

      let(:expected_query) do
        {
          query: { match_all: {} },
          _source: {
            includes: %w[obj1.* obj2.*],
            excludes: %w[*.description]
          }
        }
      end

      it 'produces the expected query' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    it 'returns itself' do
      expect(method_call).to eq(query_builder)
    end
  end

  describe '#size' do
    it 'returns itself' do
      expect(query_builder.size(5)).to eq(query_builder)
    end

    context 'with a value which is not an Integer' do
      it 'raises an ArgumentError' do
        expect { query_builder.size 'five' }
          .to raise_error(
            ArgumentError,
            'Expected `size` to be one of: Integer but String was given'
          )
      end

      context 'with a negative Integer' do
        it 'raises an ArgumentError' do
          expect { query_builder.size(-5) }
            .to raise_error(
              ArgumentError,
              '`size` should be a positive integer'
            )
        end
      end
    end
  end

  describe '#sort' do
    it 'returns itself' do
      expect(query_builder.sort(name: 'asc')).to eq(query_builder)
    end

    context 'with a parameter which is not a Hash' do
      it 'raises an ArgumentError' do
        expect { query_builder.sort('name') }
          .to raise_error(
            ArgumentError,
            'Expected `sort` to be one of: Hash but String was given'
          )
      end
    end
  end

  describe '#query' do
    subject(:method_call) { query_builder.query }

    it 'returns the created JayAPI::Elasticsearch::QueryBuilder::QueryClauses instance' do
      expect(method_call).to eq(query_clauses)
    end
  end

  describe '#collapse' do
    subject(:method_call) { query_builder.collapse(field) }

    let(:field) { 'name' }

    let(:expected_clause) do
      {
        collapse: {
          field: field
        }
      }
    end

    context 'when the given field is not a string' do
      let(:field) { %w[name age] }

      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(
          ArgumentError, 'Expected `field` to be one of: String but Array was given'
        )
      end
    end
  end

  describe '#aggregations' do
    subject(:method_call) { query_builder.aggregations }

    it 'returns the Aggregations instance' do
      expect(method_call).to eq(aggregations)
    end
  end

  describe '#to_h' do
    subject(:method_call) { query_builder.to_h }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder#to_query'
  end

  describe '#to_query' do
    subject(:method_call) { query_builder.to_query }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder#to_query'
  end

  describe '#merge' do
    subject(:method_call) { query_builder.merge(other) }

    let(:other) { described_class.new }

    let(:other_query_clauses) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses
      )
    end

    let(:merged_query_clauses) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::QueryClauses,
        to_h: { merged: 'query' }
      )
    end

    let(:other_aggregations) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations
      )
    end

    let(:merged_aggregations) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations,
        to_h: {}
      )
    end

    before do
      # Distinct doubles of the QueryClauses and Aggregation classes are needed
      # in order to be able to assert the order of the merging.

      allow(JayAPI::Elasticsearch::QueryBuilder::QueryClauses)
        .to receive(:new).and_return(query_clauses, other_query_clauses)

      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations)
        .to receive(:new).and_return(aggregations, other_aggregations)

      allow(query_clauses).to receive(:merge).and_return(merged_query_clauses)
      allow(aggregations).to receive(:merge).and_return(merged_aggregations)
    end

    context 'when the given object is not a QueryBuilder' do
      let(:other) do
        [
          described_class.new,
          described_class.new
        ]
      end

      it 'raises a TypeError' do
        expect { method_call }.to raise_error(
          TypeError,
          "Cannot merge #{described_class} and Array"
        )
      end
    end

    it "merges the receiver's query with the query from 'other'" do
      expect(query_clauses).to receive(:merge).with(other_query_clauses)
      method_call
    end

    it "merges the receiver's aggregations with the aggregations from 'other'" do
      expect(aggregations).to receive(:merge).with(other_aggregations)
      method_call
    end

    context "when neither the receiver nor +other+ have a 'sort' clause" do
      it 'does not add a sort clause to the merge result' do
        expect(method_call.to_h).not_to have_key(:sort)
      end
    end

    context "when the receiver has a sort clause but 'other' doesn't" do
      before { query_builder.sort('test_case.started_at' => :desc) }

      let(:expected_clause) do
        ['test_case.started_at' => { order: :desc }]
      end

      it 'adds the expected sort clause to the merged object (the one from the receiver)' do
        expect(method_call.to_h).to include(sort: expected_clause)
      end
    end

    context "when the receiver doesn't have a sort clause but +other+ does" do
      before do
        query_builder # This call is needed to preserve the order in which the doubles are created
        other.sort('test_case.id_long' => :asc)
      end

      let(:expected_clause) do
        ['test_case.id_long' => { order: :asc }]
      end

      it "adds the expected sort clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(sort: expected_clause)
      end
    end

    context 'when both the receiver and +other+ have sort clauses' do
      context 'when the sort clauses do not overlap' do
        before do
          query_builder.sort('test_case.started_at' => :desc)
          other.sort('test_case.id_long' => :asc)
        end

        let(:expected_clause) do
          [
            { 'test_case.started_at' => { order: :desc } },
            { 'test_case.id_long' => { order: :asc } }
          ]
        end

        it 'adds the expected sort clause to the merged object (the merge of the two clauses)' do
          expect(method_call.to_h).to include(sort: expected_clause)
        end
      end

      context 'when the sort clauses overlap' do
        before do
          query_builder.sort('test_case.started_at' => :desc)
          other.sort('test_case.started_at' => :asc)
        end

        let(:expected_clause) do
          ['test_case.started_at' => { order: :asc }]
        end

        it "adds the expected sort clause to the merged object (the one from 'other')" do
          expect(method_call.to_h).to include(sort: expected_clause)
        end
      end
    end

    context "when neither the receiver nor 'other' have 'from' clauses" do
      it "does not add a 'from' clause to the merged object" do
        expect(method_call.to_h).not_to have_key(:from)
      end
    end

    context "when the receiver has a 'from' clause but 'other' doesn't" do
      before { query_builder.from(10) }

      it "adds the expected 'from' clause to the merged object (the one from the receiver)" do
        expect(method_call.to_h).to include(from: 10)
      end
    end

    context "when the receiver doesn't have a 'from' clause but 'other' does" do
      before do
        query_builder # This call is needed to preserve the order in which the doubles are created
        other.from(25)
      end

      it "adds the expected 'from' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(from: 25)
      end
    end

    context "when both the receiver and 'other' have a 'from' clause" do
      before do
        query_builder.from(10)
        other.from(25)
      end

      it "adds the expected 'from' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(from: 25)
      end
    end

    context "when neither the receiver nor 'other' have 'size' clauses" do
      it "does not add a 'size' clause to the merged object" do
        expect(method_call.to_h).not_to have_key(:size)
      end
    end

    context "when the receiver has a 'size' clause but 'other' doesn't" do
      before { query_builder.size(100) }

      it "adds the expected 'size' clause to the merged object (the one from the receiver)" do
        expect(method_call.to_h).to include(size: 100)
      end
    end

    context "when the receiver doesn't have a 'size' clause but 'other' does" do
      before do
        query_builder # This call is needed to preserve the order in which the doubles are created
        other.size(50)
      end

      it "adds the expected 'size' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(size: 50)
      end
    end

    context "when both the receiver and 'other' have a 'size' clause" do
      before do
        query_builder.size(100)
        other.size(50)
      end

      it "adds the expected 'size' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(size: 50)
      end
    end

    context "when neither the receiver nor 'other' have 'source' clauses" do
      it "does not add a 'source' clause to the merged object" do
        expect(method_call.to_h).not_to have_key(:_source)
      end
    end

    context "when the receiver has a 'source' clause but 'other' doesn't" do
      before { query_builder.source('test_env.*') }

      it "adds the expected 'source' clause to the merged object (the one from the receiver)" do
        expect(method_call.to_h).to include(_source: 'test_env.*')
      end
    end

    context "when the receiver doesn't have a 'source' clause but 'other' does" do
      before do
        query_builder # This call is needed to preserve the order in which the doubles are created
        other.source('test_case.*')
      end

      it "adds the expected 'source' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(_source: 'test_case.*')
      end
    end

    context "when both the receiver and 'other' have a 'source' clause" do
      before do
        query_builder.source('test_env.*')
        other.source('test_case.*')
      end

      it "adds the expected 'source' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(_source: 'test_case.*')
      end
    end

    context "when neither the receiver nor 'other' have 'collapse' clauses" do
      it "does not add a 'collapse' clause to the merged object" do
        expect(method_call.to_h).not_to have_key(:collapse)
      end
    end

    context "when the receiver has a 'collapse' clause but 'other' doesn't" do
      before { query_builder.collapse('test_case.id') }

      it "adds the expected 'collapse' clause to the merged object (the one from the receiver)" do
        expect(method_call.to_h).to include(collapse: { field: 'test_case.id' })
      end
    end

    context "when the receiver doesn't have a 'collapse' clause but 'other' does" do
      before do
        query_builder # This call is needed to preserve the order in which the doubles are created
        other.collapse('test_env.build_number')
      end

      it "adds the expected 'collapse' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(collapse: { field: 'test_env.build_number' })
      end
    end

    context "when both the receiver and 'other' have a 'collapse' clause" do
      before do
        query_builder.collapse('test_case.id')
        other.collapse('test_env.build_number')
      end

      it "adds the expected 'collapse' clause to the merged object (the one from 'other')" do
        expect(method_call.to_h).to include(collapse: { field: 'test_env.build_number' })
      end
    end
  end

  describe '#clone' do
    subject(:method_call) { query_builder.clone }

    let(:query_clauses_clone) { query_clauses.clone }
    let(:aggregations_clone) { aggregations.clone }

    before do
      allow(query_clauses).to receive(:clone).and_return(query_clauses_clone)
      allow(aggregations).to receive(:clone).and_return(aggregations_clone)
    end

    shared_examples_for '#clone' do
      it "returns an instance of #{described_class}" do
        expect(method_call).to be_a(described_class)
      end

      it 'does not return the same object' do
        expect(method_call).not_to be(query_builder)
      end
    end

    context "when the receiver has no 'from' clause" do
      it_behaves_like '#clone'

      it "does not have a 'from' clause either" do
        expect(method_call.to_query).not_to have_key(:from)
      end
    end

    context "when the receiver has a 'from' clause" do
      before { query_builder.from(100) }

      it_behaves_like '#clone'

      it "has the expected 'from' clause" do
        expect(method_call.to_query).to include(from: 100)
      end
    end

    context "when the receiver has no 'size' clause" do
      it_behaves_like '#clone'

      it "does not have a 'size' clause either" do
        expect(method_call.to_query).not_to have_key(:size)
      end
    end

    context "when the receiver has a 'size' clause" do
      before { query_builder.size(500) }

      it_behaves_like '#clone'

      it "has the expected 'size' clause" do
        expect(method_call.to_query).to include(size: 500)
      end
    end

    context "when the receiver has no 'source' clause" do
      it_behaves_like '#clone'

      it "does not have a 'source' clause either" do
        expect(method_call.to_query).not_to have_key(:_source)
      end
    end

    context "when the receiver has a 'source' clause" do
      before { query_builder.source('profile.*') }

      it_behaves_like '#clone'

      it "has the expected 'source' clause" do
        expect(method_call.to_query).to include(_source: 'profile.*')
      end
    end

    context "when the 'source' changes after cloning" do
      let(:source) { %w[profile.* permissions.*] }

      before do
        query_builder.source(source)
      end

      it_behaves_like '#clone'

      it "does not change the 'source' of the clone" do
        clone = method_call
        expect { source << 'pictures.*' }.not_to change(clone, :to_query)
      end
    end

    context "when the receiver has no 'collapse' clause" do
      it_behaves_like '#clone'

      it "does not have a 'collapse' clause either" do
        expect(method_call.to_query).not_to have_key(:collapse)
      end
    end

    context "when the receiver has a 'collapse' clause" do
      before { query_builder.collapse('profile.email') }

      it_behaves_like '#clone'

      it "has the expected 'collapse' clause" do
        expect(method_call.to_query).to include(collapse: { field: 'profile.email' })
      end
    end

    context "when the receiver has no 'sort' clause" do
      it_behaves_like '#clone'

      it "does not have a 'sort' clause either" do
        expect(method_call.to_query).not_to have_key(:sort)
      end
    end

    context "when the receiver has a 'sort' clause" do
      before { query_builder.sort(age: :desc) }

      it_behaves_like '#clone'

      it "has the expected 'sort' clause" do
        expect(method_call.to_query).to include(sort: [{ age: { order: :desc } }])
      end
    end

    context "when the 'sort' changes after cloning" do
      before { query_builder.sort(age: :desc) }

      it_behaves_like '#clone'

      it "does not change the 'sort' clause of the clone" do
        clone = method_call
        expect { query_builder.sort(name: :asc) }.not_to change(clone, :to_query)
      end
    end

    it 'clones the nested QueryClauses object' do
      expect(query_clauses).to receive(:clone)
      method_call
    end

    it 'has the cloned QueryClauses object' do
      expect(method_call.query).to be(query_clauses_clone)
    end

    it 'clones the nested Aggregations object' do
      expect(aggregations).to receive(:clone)
      method_call
    end

    it 'has the cloned Aggregations object' do
      expect(method_call.aggregations).to be(aggregations_clone)
    end
  end
end
