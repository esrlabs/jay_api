# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/query_clauses'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses do
  subject(:query_clauses) do
    described_class.new
  end

  describe '#negate!' do
    subject(:method_call) { query_clauses.negate! }

    shared_examples_for '#negate! when the QueryClauses object is empty' do
      it 'changes the QueryClauses object to a match_none query' do
        expect { method_call }.to change(query_clauses, :to_h)
          .from(match_all: {}).to(match_none: {})
      end
    end

    context 'when the QueryClauses object is empty' do
      it_behaves_like '#negate! when the QueryClauses object is empty'
    end

    context 'when the QueryClauses object has a clause' do
      before { query_clauses.term(field: 'test_case.result', value: 'fail') }

      let(:original_query) do
        { term: { 'test_case.result' => { value: 'fail' } } }
      end

      let(:expected_negation) do
        {
          bool: {
            must_not: [
              { term: { 'test_case.result' => { value: 'fail' } } }
            ]
          }
        }
      end

      it 'negates the query by wrapping it in a must_not boolean clause' do
        expect { method_call }.to change(query_clauses, :to_h)
          .from(original_query).to(expected_negation)
      end
    end

    context 'when the QueryClauses object has a match_all clause' do
      before { query_clauses.match_all }

      it_behaves_like '#negate! when the QueryClauses object is empty'
    end

    context 'when the QueryClauses object has a match_none clause' do
      before { query_clauses.match_none }

      it 'changes the QueryClauses object to a match_all query' do
        expect { method_call }.to change(query_clauses, :to_h)
          .from(match_none: {}).to(match_all: {})
      end
    end
  end

  describe '#negate' do
    subject(:method_call) { query_clauses.negate }

    shared_examples_for '#negate when the QueryClauses object is empty' do
      it "does not change the object's hash representation" do
        expect { method_call }.not_to change(query_clauses, :to_h)
      end

      it 'produces a match_none query' do
        expect(method_call.to_h).to eq(match_none: {})
      end
    end

    context 'when the QueryClauses object is empty' do
      it_behaves_like '#negate when the QueryClauses object is empty'
    end

    context 'when the QueryClauses object has a clause' do
      before do
        query_clauses.bool.must do |bool_query|
          bool_query.term(field: 'test_case.result', value: 'fail')
          bool_query.exists(field: 'test_case.refs')
        end
      end

      let(:expected_negation) do
        {
          bool: {
            must_not: [
              {
                bool: {
                  must: [
                    { term: { 'test_case.result' => { value: 'fail' } } },
                    { exists: { field: 'test_case.refs' } }
                  ]
                }
              }
            ]
          }
        }
      end

      it "does not change the object's hash representation" do
        expect { method_call }.not_to change(query_clauses, :to_h)
      end

      it 'produces a negated version of the query' do
        expect(method_call.to_h).to eq(expected_negation)
      end
    end

    context 'when the QueryClauses object has a match_all clause' do
      before { query_clauses.match_all }

      it_behaves_like '#negate when the QueryClauses object is empty'
    end

    context 'when the QueryClauses object has a match_none clause' do
      before { query_clauses.match_none }

      it "does not change the object's hash representation" do
        expect { method_call }.not_to change(query_clauses, :to_h)
      end

      it 'produces a match_all query' do
        expect(method_call.to_h).to eq(match_all: {})
      end
    end
  end
end
