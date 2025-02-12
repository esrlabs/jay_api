# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder'

require_relative '../../../index'

RSpec.describe JayAPI::Elasticsearch::QueryBuilder::QueryClauses::Terms do
  subject(:matched_documents) { index.search(query) }

  let(:index_name) { 'characters_terms' }

  let(:fixture_file) { Pathname.new(__dir__) / '..' / '..' / '..' / '..' / 'test_data' / 'characters.json' }
  let(:test_data) { JSON.parse(File.read(fixture_file)) }

  let(:query_builder) do
    JayAPI::Elasticsearch::QueryBuilder.new.tap do |builder|
      builder.query.terms(field: 'origin.keyword', terms: %w[Sumeru Liyue])
    end
  end

  let(:query) { query_builder.to_query }

  let(:document_sources) do
    matched_documents.all.map { |document| document['_source'] }
  end

  let(:expected_documents) do
    [
      { 'name' => 'Nahida', 'element' => 'Dendro', 'weapon' => 'Catalyst', 'stars' => 5, 'origin' => 'Sumeru' },
      { 'name' => 'Yanfei', 'element' => 'Pyro', 'weapon' => 'Catalyst', 'stars' => 4, 'origin' => 'Liyue' },
      { 'name' => 'Keqing', 'element' => 'Electro', 'weapon' => 'Sword', 'stars' => 5, 'origin' => 'Liyue' },
      { 'name' => 'Collei', 'element' => 'Dendro', 'weapon' => 'Bow', 'stars' => 5, 'origin' => 'Sumeru' },
      { 'name' => 'Nilou', 'element' => 'Hydro', 'weapon' => 'Sword', 'stars' => 5, 'origin' => 'Sumeru' }
    ]
  end

  include_context 'with JayAPI::Elasticsearch::Index'

  before do
    next if client.transport_client.indices.exists(index: index_name)

    test_data.each do |document|
      index.push(document)
    end

    index.flush
    sleep 4
  end

  it 'produces the expected number of matched records' do
    expect(matched_documents.size).to eq(5)
  end

  it 'matches the expected set of records' do
    expect(document_sources).to match_array(expected_documents)
  end
end
