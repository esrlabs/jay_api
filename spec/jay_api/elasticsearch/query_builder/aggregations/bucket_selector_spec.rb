# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/bucket_selector'
require 'jay_api/elasticsearch/query_builder/script'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::BucketSelector do
  subject(:bucket_selector) { described_class.new(name, **constructor_params) }

  let(:name) { 'expensive_genres' }

  let(:buckets_path) do
    { 'avgPrice' => 'avg_price' }
  end

  let(:script) do
    instance_double(
      JayAPI::Elasticsearch::QueryBuilder::Script,
      to_h: {
        source: 'params.avgPrice > params.threshold',
        lang: 'painless',
        params: { threshold: 10 }
      }
    )
  end

  let(:constructor_params) do
    {
      buckets_path: buckets_path,
      script: script
    }
  end

  describe '#aggs' do
    subject(:method_call) { bucket_selector.aggs }

    let(:expected_message) { 'The Bucket Selector aggregation cannot have nested aggregations.' }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations'
  end

  describe '#clone' do
    subject(:method_call) { bucket_selector.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(bucket_selector)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(bucket_selector.name)
    end

    context "when 'buckets_path' is a String" do
      let(:buckets_path) { 'avg_price' }

      it "has the same 'buckets_path' (same object is fine)" do
        expect(method_call.buckets_path).to be(bucket_selector.buckets_path).and eq('avg_price')
      end
    end

    context "when 'buckets_path' is a Hash" do
      let(:buckets_path) do
        { 'avgPrice' => 'avg_price' }
      end

      it "has an equal 'buckets_path' but not the same object" do
        expect(method_call.buckets_path).to eq(bucket_selector.buckets_path)
        expect(method_call.buckets_path).not_to be(bucket_selector.buckets_path)
      end
    end

    it "has the same 'script'" do
      expect(method_call.script).to be(bucket_selector.script).and be(script)
    end

    context "when no 'gap_policy' is given" do
      it "has the same 'gap_policy' (nil)" do
        expect(method_call.gap_policy).to be(bucket_selector.gap_policy).and be_nil
      end
    end

    context "when a 'gap_policy' is given" do
      let(:constructor_params) do
        {
          buckets_path: buckets_path,
          script: script,
          gap_policy: 'skip'
        }
      end

      it "has the same 'gap_policy'" do
        expect(method_call.gap_policy).to be(bucket_selector.gap_policy).and eq('skip')
      end
    end
  end

  describe '#to_h' do
    subject(:method_call) { aggregation.to_h }

    let(:aggregation) { bucket_selector }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    context "when no 'gap_policy' is given" do
      let(:expected_hash) do
        {
          'expensive_genres' => {
            bucket_selector: {
              buckets_path: {
                'avgPrice' => 'avg_price'
              },
              script: {
                source: 'params.avgPrice > params.threshold',
                lang: 'painless',
                params: { threshold: 10 }
              }
            }
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when a 'gap_policy' is given" do
      let(:constructor_params) do
        {
          buckets_path: buckets_path,
          script: script,
          gap_policy: 'skip'
        }
      end

      let(:expected_hash) do
        {
          'expensive_genres' => {
            bucket_selector: {
              buckets_path: {
                'avgPrice' => 'avg_price'
              },
              script: {
                source: 'params.avgPrice > params.threshold',
                lang: 'painless',
                params: { threshold: 10 }
              },
              gap_policy: 'skip'
            }
          }
        }
      end

      it 'returns the expected Hash (including the given gap_policy)' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
