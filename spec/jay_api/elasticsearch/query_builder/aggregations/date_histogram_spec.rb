# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations/date_histogram'

require_relative 'aggregation_shared'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::Aggregations::DateHistogram do
  subject(:date_histogram) { described_class.new(name, **constructor_params) }

  let(:name) { 'sales_over_time' }
  let(:field) { 'date' }
  let(:calendar_interval) { 'month' }
  let(:constructor_params) { { field: field, calendar_interval: calendar_interval } }

  describe '#clone' do
    subject(:method_call) { aggregation.clone }

    let(:aggregation) { date_histogram }

    it 'returns an instance of the same class' do
      expect(method_call).to be_an_instance_of(described_class)
    end

    it 'is not the same object' do
      expect(method_call).not_to be(date_histogram)
    end

    it 'has the same name' do
      expect(method_call.name).to be(date_histogram.name)
    end

    it 'has the same field' do
      expect(method_call.field).to be(date_histogram.field)
    end

    it 'has the same calendar_interval' do
      expect(method_call.calendar_interval).to be(date_histogram.calendar_interval)
    end

    context 'when no format is given' do
      it 'has format set to nil' do
        expect(method_call.format).to be_nil
      end
    end

    context 'when a format is given' do
      let(:constructor_params) { super().merge(format: 'yyyy-MM-dd') }

      it 'has the same format' do
        expect(method_call.format).to be(date_histogram.format)
      end
    end

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms::#clone'
  end

  describe '#to_h' do
    subject(:method_call) { aggregation.to_h }

    let(:aggregation) { date_histogram }

    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h'
    it_behaves_like 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h with nesting allowed'

    context 'when no format is given' do
      let(:expected_hash) do
        {
          'sales_over_time' => {
            date_histogram: {
              field: 'date',
              calendar_interval: 'month'
            }
          }
        }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when a format is given' do
      let(:constructor_params) { super().merge(format: 'yyyy-MM-dd') }

      let(:expected_hash) do
        {
          'sales_over_time' => {
            date_histogram: {
              field: 'date',
              calendar_interval: 'month',
              format: 'yyyy-MM-dd'
            }
          }
        }
      end

      it 'returns the expected hash' do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
