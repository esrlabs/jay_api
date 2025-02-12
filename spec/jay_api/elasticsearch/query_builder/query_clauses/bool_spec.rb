# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses/bool'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool do
  subject(:bool_clause) { described_class.new }

  # A mock class to use when some other +QueryClause+ is needed.
  let(:dummy_clause) do
    Class.new(described_class.superclass) do
      def initialize(value)
        @value = value
        super()
      end

      def to_h
        { value: @value }
      end
    end
  end

  shared_examples_for '#must when no block is given' do
    it 'returns itself' do
      expect(method_call).to eq(bool_clause)
    end
  end

  describe '#must' do
    subject(:method_call) { bool_clause.must }

    context 'when no block is given' do
      it_behaves_like '#must when no block is given'
    end

    context 'when a block is given' do
      it 'yields itself to the block' do
        expect { |block| bool_clause.must(&block) }
          .to yield_with_args(bool_clause)
      end

      it 'returns itself' do
        expect(bool_clause.must {}).to eq(bool_clause)
      end
    end
  end

  describe '#must_not' do
    subject(:method_call) { bool_clause.must_not }

    context 'when no block is given' do
      it_behaves_like '#must when no block is given'
    end

    context 'when a block is given' do
      it 'yields itself to the block' do
        expect { |block| bool_clause.must_not(&block) }
          .to yield_with_args(bool_clause)
      end

      it 'returns itself' do
        expect(bool_clause.must_not {}).to eq(bool_clause)
      end
    end
  end

  describe '#should' do
    subject(:method_call) { bool_clause.should }

    context 'when no block is given' do
      it_behaves_like '#must when no block is given'
    end

    context 'when a block is given' do
      it 'yields itself to the block' do
        expect { |block| bool_clause.should(&block) }
          .to yield_with_args(bool_clause)
      end

      it 'returns itself' do
        expect(bool_clause.should {}).to eq(bool_clause)
      end
    end
  end

  describe '#filter' do
    subject(:method_call) { bool_clause.filter }

    context 'when no block is given' do
      it_behaves_like '#must when no block is given'
    end

    context 'when a block is given' do
      it 'yields itself to the block' do
        expect { |block| bool_clause.filter(&block) }
          .to yield_with_args(bool_clause)
      end

      it 'returns itself' do
        expect(bool_clause.filter {}).to eq(bool_clause)
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { bool_clause.to_h }

    context 'when no sub-clause have been added' do
      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
        expect { method_call }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
          'A boolean clause has been defined but no boolean sub-clauses were added'
        )
      end
    end

    context 'when boolean sub-clauses have been added' do
      before { bool_clause.must_not }

      context 'when no match-clauses have been added' do
        it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
          expect { method_call }.to raise_error(
            JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
            'A boolean clause and a sub-clause were defined but no match clauses were added'
          )
        end
      end

      context 'when match-clauses have been added' do
        let(:clauses) do
          [
            dummy_clause.new('clause1'),
            dummy_clause.new('clause2'),
            dummy_clause.new('clause3')
          ]
        end

        let(:expected_hash) do
          {
            bool: {
              must_not: [
                { value: 'clause1' },
                { value: 'clause2' }
              ],
              must: [
                { value: 'clause3' }
              ]
            }
          }
        end

        before do
          bool_clause << clauses.first
          bool_clause << clauses.second
          bool_clause.must { |bool_query| bool_query << clauses.third }
        end

        it 'returns the expected hash' do
          expect(method_call).to eq(expected_hash)
        end
      end
    end
  end

  describe '#clone' do
    subject(:method_call) { bool_clause.clone }

    shared_examples_for '#clone' do
      it 'does not raise any errors' do
        expect { method_call }.not_to raise_error
      end

      it 'returns a new instance of the class' do
        expect(method_call).to be_a(described_class)
        expect(method_call).not_to be(bool_clause)
      end
    end

    context 'when the boolean clause is empty' do
      it_behaves_like '#clone'
    end

    context 'when the boolean clause has boolean sub-clauses but not match clauses' do
      before do
        bool_clause.must
        bool_clause.filter
      end

      it_behaves_like '#clone'
    end

    context 'when the boolean clause has boolean sub-classes and match clauses' do
      let(:a_clause_clone) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
          to_h: { value: 'a clause' }
        )
      end

      let(:a_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
          to_h: { value: 'a clause' },
          clone: a_clause_clone
        )
      end

      let(:another_clause_clone) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
          to_h: { value: 'another_clause' }
        )
      end

      let(:another_clause) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
          to_h: { value: 'another_clause' },
          clone: another_clause_clone
        )
      end

      before do
        bool_clause.must do |bool_clause|
          bool_clause << a_clause
          bool_clause << another_clause
        end
      end

      it 'clones all the match clauses' do
        expect([a_clause, another_clause]).to all(receive(:clone))
        method_call
      end

      describe 'Cloned Clause' do
        subject(:cloned_clause) { method_call }

        it 'produces the same hash than the original clause' do
          expect(cloned_clause.to_h).to eq(bool_clause.to_h)
        end
      end

      context 'when the clone changes after the cloning' do
        let(:clone) { method_call }
        let(:a_new_clause) do
          instance_double(
            JayAPI::Elasticsearch::QueryBuilder::QueryClauses::QueryClause,
            to_h: { value: 'a new clause' }
          )
        end

        it "does not change the original object's hash representation" do
          expect do
            clone.must_not { |must_not| must_not << a_new_clause }
          end.not_to change(bool_clause, :to_h)
        end
      end
    end
  end

  shared_examples_for '#merge' do
    context "when 'other' is not a Bool clause nor a QueryClause" do
      let(:other) { { value: 'A suspicious Clause' } }

      it 'raises an ArgumentError' do
        expect { method_call }.to raise_error(
          ArgumentError, 'Cannot merge JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Bool with Hash'
        )
      end
    end

    context "when both the receiver and 'other' are empty" do
      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
        expect { method_call.to_h }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
          'A boolean clause has been defined but no boolean sub-clauses were added'
        )
      end
    end

    context "when either the receiver or 'other' have empty boolean clauses" do
      before do
        # Adds an empty 'must' clause to either +bool_clause+ or +other+
        [bool_clause, other].sample.must
      end

      it 'raises a JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError' do
        expect { method_call.to_h }.to raise_error(
          JayAPI::Elasticsearch::QueryBuilder::Errors::QueryBuilderError,
          'A boolean clause and a sub-clause were defined but no match clauses were added'
        )
      end
    end

    context "when 'other' is not a boolean clause" do
      let(:other) { dummy_clause.new('Some Clause') }

      context 'when the receiver is empty' do
        it "incorporates the other clause into a 'must'" do
          expect(method_call.to_h).to eq(
            { bool: { must: [{ value: 'Some Clause' }] } }
          )
        end
      end

      context "when the receiver already has a clause in its 'must'" do
        before { bool_clause.must << dummy_clause.new('My Clause') }

        it "adds 'other' into the already existing 'must'" do
          expect(method_call.to_h).to eq(
            { bool: { must: [{ value: 'My Clause' }, { value: 'Some Clause' }] } }
          )
        end
      end

      context 'when the receiver already has another boolean clause' do
        before { bool_clause.should << dummy_clause.new('My Clause') }

        it "adds 'other' into a new 'must' clause" do
          expect(method_call.to_h).to eq(
            { bool: { should: [{ value: 'My Clause' }], must: [{ value: 'Some Clause' }] } }
          )
        end
      end
    end

    context "when the receiver has clauses but 'other' is empty" do
      before { bool_clause.must_not << dummy_clause.new('My Clause') }

      it "produces an instance which only have the receiver's clauses" do
        expect(method_call.to_h).to eq(
          { bool: { must_not: [{ value: 'My Clause' }] } }
        )
      end
    end

    context "when the receiver and 'other' have different clauses" do
      before do
        bool_clause.must << dummy_clause.new('My Clause')
        other.must_not << dummy_clause.new('Not Clause')
      end

      it 'produces a compound query with the union of both' do
        expect(method_call.to_h).to eq(
          { bool: { must: [{ value: 'My Clause' }], must_not: [{ value: 'Not Clause' }] } }
        )
      end
    end

    context "when the receiver and 'other' have the same clauses" do
      before do
        bool_clause.must << dummy_clause.new('My Clause')
        other.must << dummy_clause.new('Another Clause')
      end

      it 'produces a compound query with the union of both' do
        expect(method_call.to_h).to eq(
          { bool: { must: [{ value: 'My Clause' }, { value: 'Another Clause' }] } }
        )
      end
    end
  end

  describe '#merge!' do
    subject(:method_call) { bool_clause.merge!(other) }

    let(:other) do
      described_class.new
    end

    it 'returns itself' do
      expect(method_call).to be(bool_clause)
    end

    it_behaves_like '#merge'

    describe 'nested query cloning' do
      let(:receiver_clauses) do
        (1..5).each.map { |index| dummy_clause.new("Clause #{index}") }
      end

      let(:other_clauses) do
        (6..10).each.map { |index| dummy_clause.new("Clause #{index}") }
      end

      before do
        receiver_clauses.each { |item| bool_clause.must << item }
        other_clauses.each { |item| other.must << item }
      end

      it "does not clone any of the receiver's inner clauses" do
        receiver_clauses.each do |clause|
          expect(clause).not_to receive(:clone)
        end

        method_call
      end

      it "clones only 'other's inner clauses" do
        expect(other_clauses).to all(receive(:clone))
        method_call
      end
    end
  end

  describe '#merge' do
    subject(:method_call) { bool_clause.merge(other) }

    let(:other) do
      described_class.new
    end

    it 'returns a new instance of the class' do
      expect(method_call).to be_a(described_class)
      expect(method_call).not_to be(bool_clause)
    end

    it_behaves_like '#merge'

    describe 'nested query cloning' do
      let(:dummy_clauses) do
        (1..10).each.map { |index| dummy_clause.new("Clause #{index}") }
      end

      before do
        # Adds the dummy clauses randomly to the receiver and to +other+
        dummy_clauses.each { |item| [bool_clause, other].sample.must << item }
      end

      it 'clones all the nested clauses' do
        expect(dummy_clauses).to all(receive(:clone))
        method_call
      end
    end
  end
end
