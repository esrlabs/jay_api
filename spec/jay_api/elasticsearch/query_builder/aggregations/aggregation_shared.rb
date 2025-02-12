# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder/aggregations'

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h' do
  it 'returns a Hash with single key: the name of the aggregation' do
    expect(method_call).to be_a(Hash).and have_key(name)
    expect(method_call.size).to be(1)
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#to_h with nesting allowed' do
  # Required variables:
  #  :aggregation: The +Aggregation+ instance on which the +aggs+ method should be called
  #  :name: The name given to the aggregation by the user, ex "avg_grade"

  # The actual parameters of the aggregation are hidden behind the key with its name.
  let(:aggregation_params) { method_call[name] }

  shared_context 'with a mocked Aggregations class' do
    let(:any_aggregations) { false }

    let(:aggregations) do
      instance_double(
        JayAPI::Elasticsearch::QueryBuilder::Aggregations,
        any?: any_aggregations,
        to_h: any_aggregations ? { aggs: 'Aggregations#to_h' } : {}
      )
    end

    before do
      allow(JayAPI::Elasticsearch::QueryBuilder::Aggregations)
        .to receive(:new).and_return(aggregations)
    end
  end

  shared_examples_for "#to_h when there aren't any nested aggregations" do
    it 'does not include the :aggs key' do
      expect(aggregation_params).not_to have_key(:aggs)
    end
  end

  context "when there aren't any aggregations" do
    include_context 'with a mocked Aggregations class'

    context 'when #aggs was never called' do
      it_behaves_like "#to_h when there aren't any nested aggregations"
    end

    context 'when #aggs was called but no nested aggregations were added' do
      before { aggregation.aggs }

      it_behaves_like "#to_h when there aren't any nested aggregations"
    end
  end

  context 'when #aggs was called and nested aggregations were added' do
    include_context 'with a mocked Aggregations class'

    let(:any_aggregations) { true }

    before { aggregation.aggs }

    it 'includes the :aggs key with the expected value' do
      expect(aggregation_params).to include(aggs: 'Aggregations#to_h')
    end
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#no_nested_aggregations' do
  # Required variables:
  #  :method_call: The call to the #aggs method.
  #  :expected_message: The expected message for the AggregationsError

  it 'raises a JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError' do
    expect { method_call }.to raise_error(
      JayAPI::Elasticsearch::QueryBuilder::Aggregations::Errors::AggregationsError,
      expected_message
    )
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#aggs with no block' do
  # Required variables:
  #  :aggregation: The +Aggregation+ instance on which the +aggs+ method should be called

  it 'returns a JayAPI::Elasticsearch::QueryBuilder::Aggregations' do
    expect(aggregation.aggs).to be_a(JayAPI::Elasticsearch::QueryBuilder::Aggregations)
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Aggregation#aggs with a block' do
  # Required variables:
  #  :aggregation: The +Aggregation+ instance on which the +aggs+ method should be called

  it 'returns itself' do
    expect(aggregation.aggs { nil }).to be(aggregation)
  end

  it 'yields the nested Aggregations object' do
    expect { |b| aggregation.aggs(&b) }.to yield_with_args(
      instance_of(JayAPI::Elasticsearch::QueryBuilder::Aggregations)
    )
  end
end

RSpec.shared_examples_for 'JayAPI::Elasticsearch::QueryBuilder::Aggregations::Terms::#clone' do
  # Required variables:
  #   :method_call: The result of calling the +clone+ method on +aggregation+
  #   :aggregation: The +Aggregation+ instance on which +clone+ is being called.

  describe 'hash representation' do
    subject(:hash_representation) { method_call.to_h }

    context "when there aren't any nested aggregations" do
      it "does not include the 'aggs' key" do
        expect(hash_representation[name]).not_to have_key(:aggs)
      end
    end

    context 'when there are nested aggregations' do
      let(:nested_aggregation) { aggregation.aggs { |aggs| aggs.terms('year', field: 'year') } }

      before { nested_aggregation }

      it "includes the 'aggs' key" do
        expect(hash_representation[name]).to have_key(:aggs)
      end

      context 'when the nested aggregation changes after the cloning' do
        it 'does not change' do
          expect do
            nested_aggregation.aggs { |aggs| aggs.avg('average_price', field: 'price') }
          end.not_to(change(method_call, :to_h))
        end
      end
    end
  end
end
