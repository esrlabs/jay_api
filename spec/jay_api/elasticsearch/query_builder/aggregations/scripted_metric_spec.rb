# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/scripted_metric'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric do
  subject(:scripted_metric) { described_class.new(name, **constructor_params) }

  let(:name) { 'profit' }

  let(:init_script) { 'state.transactions = []' }
  let(:map_script) { "state.transactions.add(doc.type.value == 'sale' ? doc.amount.value : -1 * doc.amount.value)" }
  let(:combine_script) { 'double profit = 0; for (t in state.transactions) { profit += t } return profit' }
  let(:reduce_script) { 'double profit = 0; for (a in states) { profit += a } return profit' }

  let(:constructor_params) do
    {
      init_script: init_script,
      map_script: map_script,
      combine_script: combine_script,
      reduce_script: reduce_script
    }
  end

  describe '#aggs' do
    subject(:method_call) { scripted_metric.aggs }

    let(:expected_message) { 'The Scripted Metric aggregation cannot have nested aggregations.' }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations'
  end

  describe '#clone' do
    subject(:method_call) { scripted_metric.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(scripted_metric)
    end

    it "has the same 'name'" do
      expect(method_call.name).to be(scripted_metric.name)
    end

    context "when the class was initialized with an 'init_script'" do
      it "has the same 'init_script'" do
        expect(method_call.init_script).to be(scripted_metric.init_script).and be(init_script)
      end
    end

    context "when the class was initialized without an 'init_script'" do
      before { constructor_params.delete(:init_script) }

      it "has the same 'init_script' (nil)" do
        expect(method_call.init_script).to be(scripted_metric.init_script).and be_nil
      end
    end

    it "has the same 'map_script'" do
      expect(method_call.map_script).to be(scripted_metric.map_script)
    end

    it "has the same 'reduce_script'" do
      expect(method_call.reduce_script).to be(scripted_metric.reduce_script)
    end
  end

  describe '#to_h' do
    let(:method_call) { described_method.call }

    # Required by the +shared_examples_for+ group to test memoization.
    let(:described_method) { scripted_metric.method(:to_h) }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'

    context 'when the init_script is present' do
      let(:expected_hash) do
        {
          'profit' => {
            scripted_metric: {
              init_script: init_script,
              map_script: map_script,
              combine_script: combine_script,
              reduce_script: reduce_script
            }
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when the init_script is not present' do
      before { constructor_params.delete(:init_script) }

      let(:expected_hash) do
        {
          'profit' => {
            scripted_metric: {
              map_script: map_script,
              combine_script: combine_script,
              reduce_script: reduce_script
            }
          }
        }
      end

      it 'returns the expected Hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
