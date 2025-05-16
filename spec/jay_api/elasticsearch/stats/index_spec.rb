# frozen_string_literal: true

require 'jay_api/elasticsearch/stats/index'

RSpec.describe JayAPI::Elasticsearch::Stats::Index do
  subject(:index) { described_class.new(name, data) }

  let(:name) { 'xyz01_integration_tests' }
  let(:data) { {} }

  describe '#initialize' do
    subject(:method_call) { index }

    it 'stores the given name' do
      method_call
      expect(index.name).to be(name)
    end
  end
end
