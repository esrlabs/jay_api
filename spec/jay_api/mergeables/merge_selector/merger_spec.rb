# frozen_string_literal: true

require 'jay_api/mergeables/merge_selector/merger'

RSpec.describe JayAPI::Mergeables::MergeSelector::Merger do
  subject(:hash_merger) do
    described_class.new(mergee, merger)
  end

  let(:mergee) do
    {
      one: {
        two: :three,
        four: :five
      },
      six: {
        seven: {
          eight: :nine
        },
        ten: :eleven
      },
      twelve: :thirteen
    }.with_indifferent_access
  end

  describe '#to_h' do
    subject(:method_call) { hash_merger.to_h }

    shared_examples_for '#to_h when the merger is empty' do
      it 'returns an empty Hash' do
        expect(method_call).to eq({})
      end
    end

    context 'when the merger is empty' do
      let(:merger) do
        {}.with_indifferent_access
      end

      it_behaves_like '#to_h when the merger is empty'
    end

    context "when the merger contains a single attribute with value nil that also exists in 'mergee'" do
      let(:merger) do
        {
          one: nil
        }.with_indifferent_access
      end

      let(:expected_hash) do
        mergee.slice(:one)
      end

      it "returns a hash with only that attribute and its child nodes in 'mergee'" do
        expect(method_call).to eq(expected_hash)
      end
    end

    context 'when the merger has several attributes with nil values' do
      let(:merger) do
        {
          one: nil,
          six: nil
        }.with_indifferent_access
      end

      let(:expected_hash) do
        mergee.slice(:one, :six)
      end

      it "returns a hash that contains only the matched attributes with values like in 'mergee'" do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when the 'merger' matches only some of the sub-nodes of 'mergee'" do
      let(:merger) do
        {
          one: nil,
          six: {
            seven: {
              eight: nil
            },
            ten: nil
          }
        }.with_indifferent_access
      end

      let(:expected_hash) do
        {
          one: mergee.dig(:one),
          six: {
            seven: {
              eight: mergee.dig(:six, :seven, :eight)
            },
            ten: mergee.dig(:six, :ten)
          }
          # , twelve: :thirteen <--- Note that this attribute does not show up in the result
        }.with_indifferent_access
      end

      it "returns a Hash that only contains those sub-nodes from 'mergee' that match the sub-nodes in 'merger'" do
        expect(method_call).to eq(expected_hash)
      end
    end

    context "when 'merger' contains a node that matches the corresponding one in 'mergee' but has a non-nil value" do
      let(:merger) do
        {
          one: nil,
          six: {
            seven: new_leaf
          }
        }.with_indifferent_access
      end

      let(:new_leaf) do
        { overwritten: :data }.with_indifferent_access
      end

      let(:expected_hash) do
        {
          one: mergee.dig(:one),
          six: {
            seven: new_leaf
          }
        }.with_indifferent_access
      end

      it "returns a Hash that contains the value specified in the 'merger' node instead of 'mergee'" do
        expect(method_call).to eq(expected_hash)
      end
    end
  end
end
