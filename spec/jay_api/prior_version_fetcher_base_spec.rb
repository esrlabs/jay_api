# frozen_string_literal: true

require 'jay_api/prior_version_fetcher_base'

RSpec.describe JayAPI::PriorVersionFetcherBase do
  subject(:fetcher) { described_class.new(client: client, index_name: index) }

  let(:client) { instance_double(JayAPI::Elasticsearch::Client) }

  let(:index) { 'build_props' }
  let(:current_version) { 'X010' }
  let(:query_results_double) { instance_double(JayAPI::Elasticsearch::QueryResults) }
  let(:results_array) { [] }

  let(:query_builder_double) do
    instance_double(JayAPI::Elasticsearch::QueryBuilder, to_query: { 'fields' => 'from query builder' })
  end

  describe '#prior_version' do
    subject(:method_call) { fetcher.prior_version(current_version: current_version) }

    let(:index_double) { instance_double(JayAPI::Elasticsearch::Index, search: query_results_double) }

    before do
      allow(JayAPI::Elasticsearch::Index).to receive(:new).and_return(index_double)
      allow(JayAPI::Elasticsearch::QueryBuilder).to receive(:new).and_return(query_builder_double)
      allow(query_builder_double).to receive(:collapse).and_return(query_builder_double)

      allow(query_results_double).to receive(:all) do |&block|
        results_array.each(&block)
      end
    end

    context 'when :compute_last_version function is not called from the base class' do
      before do
        # Mocking the injected function, since not defined in base class
        allow(fetcher).to receive(:compute_last_version).and_return(nil)
      end

      it 'initializes the Index object properly' do
        expect(JayAPI::Elasticsearch::Index).to receive(:new).with(
          client: client,
          index_name: index
        )

        method_call
      end

      it 'builds the proper query' do
        expect(query_builder_double).to receive(:collapse).with('build_properties.version_code.keyword')

        method_call
      end

      it 'calls the :search function on the Index object' do
        expect(index_double).to receive(:search).with({ 'fields' => 'from query builder' })

        method_call
      end
    end

    context 'when :compute_last_version function is called from the base class' do
      it 'raises a NotImplementedError' do
        expect { method_call }.to raise_error(NotImplementedError)
      end
    end
  end
end
