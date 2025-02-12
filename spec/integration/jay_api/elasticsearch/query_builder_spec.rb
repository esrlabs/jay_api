# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder do
  subject(:query_builder) { described_class.new }

  shared_examples_for '#to_h' do
    context 'without query clauses or aggregations' do
      let(:expected_query) do
        {
          query: {
            match_all: {}
          }
        }
      end

      it 'returns the expected match all query' do
        expect(method_call).to eq(expected_query)
      end
    end

    context 'with a simple aggregation' do
      before do
        query_builder.aggregations.terms('genres', field: 'genre')
      end

      let(:expected_query) do
        {
          query: {
            match_all: {}
          },
          aggs: {
            'genres' => {
              terms: { field: 'genre' }
            }
          }
        }
      end

      it 'returns the expected query with the aggregation' do
        expect(method_call).to eq(expected_query)
      end
    end

    context 'with two aggregations' do
      before do
        query_builder.aggregations.terms('genres', field: 'genre')
        query_builder.aggregations.avg('average_price', field: 'price')
      end

      let(:expected_query) do
        {
          query: {
            match_all: {}
          },
          aggs: {
            'genres' => {
              terms: { field: 'genre' }
            },
            'average_price' => {
              avg: { field: 'price' }
            }
          }
        }
      end

      it 'returns the expected query with both aggregations' do
        expect(method_call).to eq(expected_query)
      end
    end

    context 'with a nested aggregation' do
      before do
        query_builder.aggregations.terms('build_jobs', field: 'test_env.build_job_name.keyword')
                     .aggs.avg('average_runtime', field: 'test_case.runtime')
      end

      let(:expected_query) do
        {
          query: {
            match_all: {}
          },
          aggs: {
            'build_jobs' => {
              terms: { field: 'test_env.build_job_name.keyword' },
              aggs: {
                'average_runtime' => {
                  avg: { field: 'test_case.runtime' }
                }
              }
            }
          }
        }
      end

      it 'returns the expected query with the second aggregation nested inside the first' do
        expect(method_call).to eq(expected_query)
      end
    end

    context 'with multiple nested aggregations' do
      before do
        query_builder.aggregations.terms('build_jobs', field: 'test_env.build_job_name.keyword').aggs do |aggs|
          aggs.terms('sut_revisions', field: 'test_env.sut_revision.keyword')
          aggs.avg('average_runtime', field: 'test_case.runtime')
        end
      end

      let(:expected_query) do
        {
          query: {
            match_all: {}
          },
          aggs: {
            'build_jobs' => {
              terms: { field: 'test_env.build_job_name.keyword' },
              aggs: {
                'sut_revisions' => {
                  terms: { field: 'test_env.sut_revision.keyword' }
                },
                'average_runtime' => {
                  avg: { field: 'test_case.runtime' }
                }
              }
            }
          }
        }
      end

      it 'returns the expected query with both aggregations nested inside the first' do
        expect(method_call).to eq(expected_query)
      end
    end

    context 'with complex filter aggregations' do
      before do
        filter = query_builder.aggregations.filter('hats') do |query|
          query.term(field: 'type', value: 'hat')
        end

        filter.aggs { |aggs| aggs.avg('avg_price', field: 'price') }

        filter = query_builder.aggregations.filter('t_shirts') do |query|
          query.term(field: 'type', value: 't-shirt')
        end

        filter.aggs { |aggs| aggs.avg('avg_price', field: 'price') }
      end

      let(:expected_query) do
        {
          query: { match_all: {} },
          aggs: {
            'hats' => {
              filter: { term: { 'type' => { value: 'hat' } } },
              aggs: {
                'avg_price' => { avg: { field: 'price' } }
              }
            },
            't_shirts' => {
              filter: { term: { 'type' => { value: 't-shirt' } } },
              aggs: {
                'avg_price' => { avg: { field: 'price' } }
              }
            }
          }
        }
      end

      it 'returns the expected query with both filter aggregations and their queries' do
        expect(method_call).to eq(expected_query)
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { query_builder.to_h }

    it_behaves_like '#to_h'
  end

  describe '#to_query' do
    subject(:method_call) { query_builder.to_query }

    it_behaves_like '#to_h'
  end

  describe '#merge' do
    subject(:method_call) { query_builder.merge(other) }

    let(:other) { described_class.new }

    context 'when the QueryBuilder has nested aggregations' do
      before do
        query_builder.aggregations.avg('overall_avg_price', field: 'price')
        query_builder.aggregations.filter('hats') { |query| query.term(field: 'type', value: 'hat') }
                     .aggs { |aggs| aggs.avg('avg_price', field: 'price') }

        other.aggregations.filter('t_shirts') { |query| query.term(field: 'type', value: 't-shirt') }
             .aggs { |aggs| aggs.avg('avg_price', field: 'price') }
      end

      let(:expected_query) do
        {
          query: { match_all: {} },
          aggs: {
            'overall_avg_price' => { avg: { field: 'price' } },
            'hats' => {
              filter: { term: { 'type' => { value: 'hat' } } },
              aggs: {
                'avg_price' => { avg: { field: 'price' } }
              }
            },
            't_shirts' => {
              filter: { term: { 'type' => { value: 't-shirt' } } },
              aggs: {
                'avg_price' => { avg: { field: 'price' } }
              }
            }
          }
        }
      end

      it 'preserves the nested aggregations' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when the receiver has a simple clause and the mergee is empty' do
      before do
        query_builder.query.term(field: 'user.name', value: 'kimchy')
      end

      let(:expected_query) do
        {
          query: {
            term: {
              'user.name' => { value: 'kimchy' }
            }
          }
        }
      end

      it 'produces the expected query (only has one simple query)' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when the receiver is empty and the mergee has a simple clause' do
      before do
        other.query.range(field: 'age', gte: 10, lte: 20)
      end

      let(:expected_query) do
        {
          query: {
            range: {
              'age' => { gte: 10, lte: 20 }
            }
          }
        }
      end

      it 'produces the expected query (only has one simple query)' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when two simple queries are merged' do
      before do
        query_builder.query.term(field: 'user.name', value: 'kimchy')
        other.query.range(field: 'age', gte: 10, lte: 20)
      end

      let(:expected_query) do
        {
          query: {
            bool: {
              must: [
                { term: { 'user.name' => { value: 'kimchy' } } },
                { range: { 'age' => { gte: 10, lte: 20 } } }
              ]
            }
          }
        }
      end

      it "merges both query using a boolean 'must' (equivalent to AND)" do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when two boolean queries are merged' do
      before do
        query_builder.query.bool.must do |bool_query|
          bool_query.term(field: 'user.name', value: 'kimchy')
          bool_query.range(field: 'age', gte: 10, lte: 20)
        end

        other.query.bool.must do |bool_query|
          bool_query.exists(field: 'user.pet')
        end
      end

      let(:expected_query) do
        {
          query: {
            bool: {
              must: [
                { term: { 'user.name' => { value: 'kimchy' } } },
                { range: { 'age' => { gte: 10, lte: 20 } } },
                { exists: { field: 'user.pet' } }
              ]
            }
          }
        }
      end

      it "merges the two queries without producing a nested 'must'" do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when two boolean queries with non-overlapping clauses are merged' do
      before do
        query_builder.query.bool.must do |bool_query|
          bool_query.term(field: 'user.name', value: 'kimchy')
          bool_query.range(field: 'age', gte: 10, lte: 20)
        end

        other.query.bool.must_not do |bool_query|
          bool_query.exists(field: 'user.pet')
        end
      end

      let(:expected_query) do
        {
          query: {
            bool: {
              must: [
                { term: { 'user.name' => { value: 'kimchy' } } },
                { range: { 'age' => { gte: 10, lte: 20 } } }
              ],
              must_not: [
                { exists: { field: 'user.pet' } }
              ]
            }
          }
        }
      end

      it 'merges the two queries as expected (preserves the boolean clauses)' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end

    context 'when two boolean queries with overlapping and non-overlapping clauses are merged' do
      before do
        query_builder.query.bool.must do |bool_query|
          bool_query.term(field: 'user.name', value: 'kimchy')
        end

        query_builder.query.bool.must_not do |bool_query|
          bool_query.range(field: 'age', gte: 10, lte: 20)
        end

        other.query.bool.must do |bool_query|
          bool_query.exists(field: 'user.pet')
        end
      end

      let(:expected_query) do
        {
          query: {
            bool: {
              must: [
                { term: { 'user.name' => { value: 'kimchy' } } },
                { exists: { field: 'user.pet' } }
              ],
              must_not: [
                { range: { 'age' => { gte: 10, lte: 20 } } }
              ]
            }
          }
        }
      end

      it 'merges the two queries as expected (overlapping boolean clauses are merged together)' do
        expect(method_call.to_query).to eq(expected_query)
      end
    end
  end
end
