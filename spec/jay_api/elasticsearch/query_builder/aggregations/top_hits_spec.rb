# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/top_hits'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits do
  subject(:top_hits) { described_class.new(name, **constructor_params) }

  let(:name) { 'an_aggregation_sample' }

  let(:constructor_params) do
    { size: 1 }
  end

  describe '#clone' do
    subject(:method_call) { top_hits.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(top_hits)
    end

    it "has the same 'size'" do
      expect(method_call.size).to be(top_hits.size)
    end

    context "when no 'sort' has been given" do
      it "has its 'sort' set to nil" do
        expect(method_call.sort).to be_nil
      end
    end

    context "when a 'sort' has been given" do
      let(:sort) { { timestamp: :desc } }
      let(:constructor_params) { super().merge(sort: sort) }

      it "has its 'sort' set to the same value" do
        expect(method_call.sort).to eq(sort)
      end

      it 'is not the same hash' do
        expect(method_call.sort).not_to be(top_hits.sort)
      end
    end

    shared_examples_for "#clone when a '_source' has been given" do
      it "has its '_source' set to the same value" do
        expect(method_call._source).to eq(_source)
      end
    end

    shared_examples_for "#clone when a non-scalar '_source' has been given" do
      it_behaves_like "#clone when a '_source' has been given"

      it 'is not the same object' do
        expect(method_call._source).not_to be(top_hits._source)
      end
    end

    context "when a '_source' has been given" do
      let(:constructor_params) { super().merge(_source:) }

      context "when '_source' is a boolean" do
        let(:_source) { false }

        it_behaves_like "#clone when a '_source' has been given"
      end

      context "when '_source' is a string" do
        let(:_source) { 'meta_data.*' }

        it_behaves_like "#clone when a non-scalar '_source' has been given"
      end

      context "when '_source' is an array" do
        let(:_source) { %w[meta_data.* timestamp] }

        it_behaves_like "#clone when a non-scalar '_source' has been given"
      end

      context "when '_source' is a hash" do
        let(:_source) do
          { includes: %i[date price] }
        end

        it_behaves_like "#clone when a non-scalar '_source' has been given"
      end
    end

    context 'when the original object has nested aggregations' do
      let(:cloned_aggregations) { instance_double(JayAPI::Elasticsearch::QueryBuilder::Aggregations) }

      let(:aggregations) do
        instance_double(JayAPI::Elasticsearch::QueryBuilder::Aggregations, clone: cloned_aggregations)
      end

      before do
        allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations).to receive(:new).and_return(aggregations)
        # This initializes a nested aggregation object in the original object, so that it can be cloned.
        top_hits.aggs
      end

      it 'has the cloned aggregations' do
        expect(method_call.aggs).to be(cloned_aggregations)
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { top_hits.to_h }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    context "when no 'sort' has been given" do
      let(:expected_hash) do
        {
          'an_aggregation_sample' => {
            top_hits: { size: 1 }
          }
        }
      end

      it 'returns the expected Hash (does not include the :sort key)' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when a 'sort' has been given" do
      let(:sort) { { timestamp: :desc } }
      let(:constructor_params) { super().merge(sort: sort) }

      let(:expected_hash) do
        {
          'an_aggregation_sample' => {
            top_hits: {
              size: 1,
              sort: { timestamp: :desc }
            }
          }
        }
      end

      it 'returns the expected Hash (includes the expected :sort key)' do
        expect(method_call).to eq(expected_hash)
      end

      it "does not return a reference to the internal 'sort' Hash" do
        sort_hash = method_call.dig('an_aggregation_sample', :top_hits, :sort)
        expect(sort_hash).not_to be(top_hits.sort)
        expect(sort_hash).to eq(sort)
      end
    end

    context "when a '_source' has been given" do
      let(:constructor_params) { super().merge(_source:) }

      context "when '_source' is a scalar" do
        let(:_source) { false }

        let(:expected_hash) do
          {
            'an_aggregation_sample' => {
              top_hits: {
                size: 1,
                _source: false
              }
            }
          }
        end

        it 'returns the expected Hash' do
          expect(method_call).to eq(expected_hash)
        end
      end

      context "when '_source' is not a scalar" do
        let(:_source) { %w[meta_data.* timestamp] }

        let(:expected_hash) do
          {
            'an_aggregation_sample' => {
              top_hits: {
                size: 1,
                _source: %w[meta_data.* timestamp]
              }
            }
          }
        end

        it 'returns the expected Hash' do
          expect(method_call).to eq(expected_hash)
        end

        it "does not return a reference to the internal '_source' object" do
          source_hash = method_call.dig('an_aggregation_sample', :top_hits, :_source)
          expect(source_hash).not_to be(top_hits._source)
          expect(source_hash).to eq(_source)
        end
      end
    end
  end
end
