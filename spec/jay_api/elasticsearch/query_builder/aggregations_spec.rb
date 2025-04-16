# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations'
require 'jay_api/elasticsearch/query_builder/script'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations do
  subject(:aggregations) { described_class.new }

  let(:name) { 'jobs' }
  let(:field) { 'test_env.Job Name.keyword' }

  let(:another_name) { 'runtime' }
  let(:another_field) { 'test_case.runtime' }

  describe '#any?' do
    subject(:method_call) { aggregations.any? }

    context "when there aren't any aggregations" do
      it 'returns false' do
        expect(method_call).to be(false)
      end
    end

    context 'when there is at least one aggregation' do
      before do
        aggregations.terms('revisions', field: 'test_environment.sut_revision')
      end

      it 'returns true' do
        expect(method_call).to be(true)
      end
    end
  end

  describe '#none?' do
    subject(:method_call) { aggregations.none? }

    context "when there aren't any aggregations" do
      it 'returns true' do
        expect(method_call).to be(true)
      end
    end

    context 'when there is at least one aggregation' do
      before do
        aggregations.avg('runtime', field: 'test_case.runtime')
      end

      it 'returns false' do
        expect(method_call).to be(false)
      end
    end
  end

  describe '#terms' do
    subject(:method_call) do
      aggregations.terms(
        name, field: field
      )
    end

    let(:name) { 'genres' }
    let(:field) { 'genre' }

    let(:terms) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms,
        to_h: { terms: 'Terms#to_h' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms)
        .to receive(:new).and_return(terms)
    end

    it 'creates the Terms instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms)
        .to receive(:new).with(name, field: field, script: nil, size: nil, order: nil)

      method_call
    end

    context 'when size is provided' do
      subject(:method_call) do
        aggregations.terms(
          name, field: field, size: 100
        )
      end

      it 'creates the Terms instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms)
          .to receive(:new).with(name, field: field, script: nil, size: 100, order: nil)

        method_call
      end
    end

    context 'when order is provided' do
      subject(:method_call) do
        aggregations.terms(
          name, field: field, order: { _key: :asc }
        )
      end

      it 'creates the Terms instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms)
          .to receive(:new).with(name, field: field, script: nil, size: nil, order: { _key: :asc })

        method_call
      end
    end

    context 'when a script is provided' do
      subject(:method_call) do
        aggregations.terms(
          name, field: field, script: script
        )
      end

      let(:script) do
        instance_double(
          JayAPI::Elasticsearch::QueryBuilder::Script
        )
      end

      it 'creates the Terms instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms)
          .to receive(:new).with(name, field: field, script: script, size: nil, order: nil)

        method_call
      end
    end

    it 'adds the Terms instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { terms: 'Terms#to_h' })
    end
  end

  describe '#avg' do
    subject(:method_call) do
      aggregations.avg(
        name, field: field
      )
    end

    let(:name) { 'avg_grade' }
    let(:field) { 'grade' }

    let(:avg) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg,
        to_h: { terms: 'Avg#to_h' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg)
        .to receive(:new).and_return(avg)
    end

    it 'creates the Avg instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg)
        .to receive(:new).with(name, field: field, missing: nil)

      method_call
    end

    context 'when a "missing" value is provided' do
      subject(:method_call) do
        aggregations.avg(
          name, field: field, missing: 10
        )
      end

      it 'creates the Avg instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Avg)
          .to receive(:new).with(name, field: field, missing: 10)

        method_call
      end
    end

    it 'adds the Avg instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { terms: 'Avg#to_h' })
    end
  end

  describe '#max' do
    subject(:method_call) do
      aggregations.max(
        name, field: field
      )
    end

    let(:name) { 'max_price' }
    let(:field) { 'price' }

    let(:max) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Max,
        to_h: { terms: 'Max#to_h' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Max)
        .to receive(:new).and_return(max)
    end

    it 'creates the Max instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Max)
        .to receive(:new).with(name, field: field)

      method_call
    end

    it 'adds the Max instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { terms: 'Max#to_h' })
    end
  end

  describe '#sum' do
    subject(:method_call) do
      aggregations.sum(
        name, field: field
      )
    end

    let(:name) { 'hat_prices' }
    let(:field) { 'price' }

    let(:sum) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum,
        to_h: { 'sum' => { '#to_h' => {} } }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum)
        .to receive(:new).and_return(sum)
    end

    it 'creates the Sum instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum)
        .to receive(:new).with(name, field: field, missing: nil)

      method_call
    end

    context 'when a "missing" value is provided' do
      subject(:method_call) do
        aggregations.sum(
          name, field: field, missing: 100
        )
      end

      it 'creates the Sum instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Sum)
          .to receive(:new).with(name, field: field, missing: 100)

        method_call
      end
    end

    it 'adds the Sum instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { 'sum' => { '#to_h' => {} } })
    end
  end

  describe '#value_count' do
    subject(:method_call) do
      aggregations.value_count(
        name, field: field
      )
    end

    let(:name) { 'types_count' }
    let(:field) { 'type' }

    let(:value_count) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount,
        to_h: { 'value_count' => { '#to_h' => {} } }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount)
        .to receive(:new).and_return(value_count)
    end

    it 'creates the ValueCount instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::ValueCount)
        .to receive(:new).with(name, field: field)

      method_call
    end

    it 'adds the ValueCount instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { 'value_count' => { '#to_h' => {} } })
    end
  end

  describe '#filter' do
    subject(:method_call) do
      aggregations.filter(name, &block)
    end

    let(:name) { 'hats' }
    let(:block) { proc { |query| query.term(field: 'type', value: 'hat') } }

    let(:filter) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter,
        to_h: { 'filter' => { '#to_h' => {} } }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter)
        .to receive(:new).and_return(filter)
    end

    # rubocop:disable RSpec/MultipleExpectations (Cannot be done with a simple matcher, because of the block)
    it 'creates the Filter instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Filter).to receive(:new) do |passed_name, &passed_block|
        expect(passed_name).to be(name)
        expect(passed_block).to be(block)
      end

      method_call
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'adds the Filter instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { 'filter' => { '#to_h' => {} } })
    end
  end

  describe '#cardinality' do
    subject(:method_call) do
      aggregations.cardinality(name, field: field)
    end

    let(:name) { 'type_count' }
    let(:field) { 'type' }

    let(:cardinality) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::Cardinality,
        to_h: { 'cardinality' => { '#to_h' => {} } }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Cardinality)
        .to receive(:new).and_return(cardinality)
    end

    it 'creates the Cardinality instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::Cardinality).to receive(:new).with(name, field: field)
      method_call
    end

    it 'adds the Cardinality instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { 'cardinality' => { '#to_h' => {} } })
    end
  end

  describe '#date_histogram' do
    subject(:method_call) do
      aggregations.date_histogram(name, **method_params)
    end

    let(:name) { 'sales_over_time' }
    let(:field) { 'date' }
    let(:calendar_interval) { 'month' }
    let(:method_params) { { field: field, calendar_interval: calendar_interval } }

    let(:date_histogram) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::DateHistogram,
        to_h: { 'date_histogram' => { '#to_h' => {} } }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::DateHistogram)
        .to receive(:new).and_return(date_histogram)
    end

    shared_examples_for '#date_histogram' do
      it 'adds the DateHistogram instance to the array of aggregations' do
        expect { method_call }.to change(aggregations, :to_h).to(aggs: { 'date_histogram' => { '#to_h' => {} } })
      end
    end

    shared_examples_for '#date_histogram when no format is given' do
      it 'creates the Cardinality instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::DateHistogram).to receive(:new)
          .with(name, field: field, calendar_interval: calendar_interval, format: nil)

        method_call
      end
    end

    context 'when no format is given' do
      it_behaves_like '#date_histogram when no format is given'
      it_behaves_like '#date_histogram'
    end

    context 'when format is given as nil' do
      let(:method_params) { super().merge(format: nil) }

      it_behaves_like '#date_histogram when no format is given'
      it_behaves_like '#date_histogram'
    end

    context 'when a format is given' do
      let(:format) { 'yyyy-MM-dd' }
      let(:method_params) { super().merge(format: format) }

      it 'creates the Cardinality instance with the expected parameters' do
        expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::DateHistogram).to receive(:new)
          .with(name, field: field, calendar_interval: calendar_interval, format: format)

        method_call
      end

      it_behaves_like '#date_histogram'
    end
  end

  describe '#top_hits' do
    subject(:method_call) do
      aggregations.top_hits(name, size: size)
    end

    let(:name) { 'recent_logs' }
    let(:size) { 10 }

    let(:top_hits) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits,
        to_h: { top_hits: 'TopHits#to_h' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits)
        .to receive(:new).and_return(top_hits)
    end

    it 'creates the TopHits instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::TopHits)
        .to receive(:new).with(name, size: size)

      method_call
    end

    it 'adds the TopHits instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { top_hits: 'TopHits#to_h' })
    end
  end

  describe '#scripted_metric' do
    subject(:method_call) do
      aggregations.scripted_metric(
        name,
        init_script: init_script, map_script: map_script,
        combine_script: combine_script, reduce_script: reduce_script
      )
    end

    let(:name) { 'profit' }
    let(:init_script) { 'init_script": "state.transactions = []' }
    let(:map_script) { "state.transactions.add(doc.type.value == 'sale' ? doc.amount.value : -1 * doc.amount.value)" }
    let(:combine_script) { 'double profit = 0; for (t in state.transactions) { profit += t } return profit' }
    let(:reduce_script) { 'double profit = 0; for (a in states) { profit += a } return profit' }

    let(:scripted_metric) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric,
        to_h: { scripted_metric: 'ScriptedMetric#to_h' }
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric)
        .to receive(:new).and_return(scripted_metric)
    end

    it 'creates the ScriptedMetric instance with the expected parameters' do
      expect(JayAPI::Elasticsearch::QueryBuilder::Aggregations::ScriptedMetric)
        .to receive(:new).with(name, init_script: init_script, map_script: map_script,
                                     combine_script: combine_script, reduce_script: reduce_script)

      method_call
    end

    it 'adds the ScriptedMetric instance to the array of aggregations' do
      expect { method_call }.to change(aggregations, :to_h).to(aggs: { scripted_metric: 'ScriptedMetric#to_h' })
    end
  end

  describe '#to_h' do
    subject(:method_call) { aggregations.to_h }

    before do
      aggregations.terms(name, field: field)
      aggregations.avg(another_name, field: another_field)
    end

    let(:expected_hash) do
      {
        aggs: {
          name => {
            terms: {
              field: field
            }
          },
          another_name => {
            avg: {
              field: another_field
            }
          }
        }
      }
    end

    it 'returns the expected Hash' do
      expect(method_call).to eq(expected_hash)
    end
  end

  describe '#merge' do
    subject(:method_call) { aggregations.merge(other) }

    let(:other) { described_class.new }

    shared_examples_for '#merge' do
      it 'raises no error' do
        expect { method_call }.not_to raise_error
      end

      it 'returns an Aggregations object' do
        expect(method_call).to be_a(described_class)
      end

      it "does not return the receiver nor 'other'" do
        expect(method_call).not_to be(aggregations)
        expect(method_call).not_to be(other)
      end
    end

    context "when other is not a #{described_class}" do
      let(:other) do
        {
          'my-agg-name': {
            terms: {
              field: 'my-field'
            }
          }
        }
      end

      it 'raises a TypeError' do
        expect { method_call }.to raise_error(
          TypeError,
          "Cannot merge #{described_class} with Hash"
        )
      end
    end

    context "when both the receiver and 'other' are empty" do
      it_behaves_like '#merge'

      it 'has the same hash representation as the receiver' do
        expect(method_call.to_h).to eq(aggregations.to_h)
      end
    end

    context "when the receiver is not empty but 'other' is" do
      let(:expected_hash) do
        {
          aggs: {
            'avg_runtime' => {
              avg: { field: 'test_case.runtime' }
            }
          }
        }
      end

      before do
        aggregations.avg('avg_runtime', field: 'test_case.runtime')
      end

      it_behaves_like '#merge'

      it 'has the expected hash representation (what the receiver alone would produce)' do
        expect(method_call.to_h).to eq(expected_hash)
      end
    end

    context "when the receiver is empty but 'other' is not" do
      let(:expected_hash) do
        {
          aggs: {
            'unique_tests' => {
              terms: {
                field: 'test_case.id_long'
              }
            }
          }
        }
      end

      before do
        other.terms('unique_tests', field: 'test_case.id_long')
      end

      it_behaves_like '#merge'

      it "has the expected hash representation (what 'other' alone would produce)" do
        expect(method_call.to_h).to eq(expected_hash)
      end
    end

    context "when neither the receiver nor 'other' are empty" do
      context 'when the aggregations do not overlap' do
        let(:expected_hash) do
          {
            aggs: {
              'avg_runtime' => {
                avg: { field: 'test_case.runtime' }
              },
              'unique_tests' => {
                terms: {
                  field: 'test_case.id_long'
                }
              }
            }
          }
        end

        before do
          aggregations.avg('avg_runtime', field: 'test_case.runtime')
          other.terms('unique_tests', field: 'test_case.id_long')
        end

        it_behaves_like '#merge'

        it 'has the expected hash representation (the merge of both objects)' do
          expect(method_call.to_h).to eq(expected_hash)
        end
      end

      context 'when the aggregations overlap' do
        let(:expected_hash) do
          {
            aggs: {
              'avg_runtime' => {
                avg: { field: 'test_run.runtime' }
              }
            }
          }
        end

        before do
          aggregations.avg('avg_runtime', field: 'test_case.runtime')
          other.avg('avg_runtime', field: 'test_run.runtime')
        end

        it "has the expected hash representation ('other' overrides the receiver's)" do
          expect(method_call.to_h).to eq(expected_hash)
        end
      end
    end
  end

  describe '#clone' do
    subject(:method_call) { aggregations.clone }

    it 'returns an instance of the same class' do
      expect(method_call).to be_a(described_class)
    end

    it 'does not return the same object' do
      expect(method_call).not_to be(aggregations)
    end

    context 'when some aggregations already exist' do
      before do
        aggregations.terms(name, field: field)
        aggregations.avg(another_name, field: another_field)
      end

      it 'copies those aggregations' do
        expect(method_call.to_h).to eq(aggregations.to_h)
      end
    end

    context 'when aggregations are added after the cloning' do
      it 'does not add those aggregations to the clone as well' do
        expect do
          aggregations.terms(name, field: field)
        end.not_to change(method_call, :any?)
      end
    end
  end
end
