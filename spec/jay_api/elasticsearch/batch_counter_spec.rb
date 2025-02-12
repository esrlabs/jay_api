# frozen_string_literal: true

require 'jay_api/elasticsearch/batch_counter'

RSpec.describe JayAPI::Elasticsearch::BatchCounter do
  let(:query_size) { 10 }
  let(:query_from) { 5 }
  let(:size) { 15 }

  let(:query) { { size: query_size, from: query_from } }

  describe '.create_or_update' do
    subject(:method_call) { described_class.create_or_update(existing_counter, query, size) }

    shared_examples_for 'BatchCounter with correct attributes' do
      it 'has the expected attributes' do
        expect(method_call).to have_attributes(
          batch_size: expected_batch_size, start_current: expected_start_current, start_next: expected_start_next
        )
      end
    end

    context 'without an existing batch counter' do
      let(:existing_counter) { nil }

      context "when the query has the 'size' and 'from' entries" do
        let(:expected_batch_size) { query_size }
        let(:expected_start_current) { query_from }
        let(:expected_start_next) { query_from + size }

        it_behaves_like 'BatchCounter with correct attributes'
      end

      context "when the query only has the 'size' entry" do
        let(:query_from) { nil }

        let(:expected_batch_size) { query_size }
        let(:expected_start_current) { 0 }
        let(:expected_start_next) { size }

        it_behaves_like 'BatchCounter with correct attributes'
      end

      context "when the query only has the 'from' entry" do
        let(:query_size) { nil }

        let(:expected_batch_size) { size }
        let(:expected_start_current) { query_from }
        let(:expected_start_next) { query_from + size }

        it_behaves_like 'BatchCounter with correct attributes'
      end

      context 'when the query is empty' do
        let(:query) { {} }

        let(:expected_batch_size) { size }
        let(:expected_start_current) { 0 }
        let(:expected_start_next) { size }

        it_behaves_like 'BatchCounter with correct attributes'
      end
    end

    context 'with an existing batch counter' do
      let(:existing_counter) do
        described_class.new({}, 0, existing_start_current, existing_start_next, existing_batch_size)
      end

      shared_examples_for 'BatchCounter with an existing counter' do
        let(:existing_batch_size) { 6 }
        let(:existing_start_current) { 3 }
        let(:existing_start_next) { 14 }

        let(:expected_batch_size) { existing_batch_size }
        let(:expected_start_current) { existing_start_next }
        let(:expected_start_next) { existing_start_next + size }

        it_behaves_like 'BatchCounter with correct attributes'
      end

      context "when the query has the 'size' and 'from' entries" do
        it_behaves_like 'BatchCounter with an existing counter'
      end

      context "when the query only has the 'size' entry" do
        let(:query_from) { nil }

        it_behaves_like 'BatchCounter with an existing counter'
      end

      context "when the query only has the 'from' entry" do
        let(:query_size) { nil }

        it_behaves_like 'BatchCounter with an existing counter'
      end

      context 'when the query is empty' do
        let(:query) { {} }

        it_behaves_like 'BatchCounter with an existing counter'
      end
    end
  end
end
