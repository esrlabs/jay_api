# frozen_string_literal: true

require 'jay_api/elasticsearch/count'

RSpec.describe JayAPI::Elasticsearch::Count do
  subject(:count_response) { described_class.new(data) }

  let(:data) { { 'count' => 10 } }

  let(:int_like) do
    Class.new do
      def initialize(value)
        @value = value
      end

      def to_int
        @value
      end
    end.new(5)
  end

  describe '#count' do
    it 'returns the raw count from the payload' do
      expect(count_response.count).to eq(10)
    end
  end

  describe '#to_i' do
    it 'returns the integer value' do
      expect(count_response.to_i).to eq(10)
    end
  end

  describe '#to_int' do
    it 'returns the integer value' do
      expect(count_response.to_int).to eq(10)
    end
  end

  describe '#to_s' do
    it 'returns the count as a string' do
      expect(count_response.to_s).to eq('10')
    end
  end

  describe '#coerce' do
    it 'coerces numeric values into a pair for arithmetic' do
      expect(count_response.coerce(4)).to eq([4, 10])
    end

    it 'coerces objects responding to to_int' do
      expect(count_response.coerce(int_like)).to eq([5, 10])
    end

    it 'raises a TypeError for unsupported values' do
      expect { count_response.coerce('value') }
        .to raise_error(TypeError, 'String cannot be coerced into Integer')
    end
  end

  describe '#<=>' do
    it 'compares with integers' do
      expect(count_response <=> 10).to eq(0)
    end

    it 'orders lower when compared with a greater integer' do
      expect(count_response <=> 11).to eq(-1)
    end

    it 'orders greater when compared with a smaller integer' do
      expect(count_response <=> 9).to eq(1)
    end

    it 'compares with a greater float' do
      expect(count_response <=> 10.5).to eq(-1)
    end

    it 'compares with a smaller float' do
      expect(count_response <=> 9.5).to eq(1)
    end

    it 'compares with objects responding to to_int' do
      expect(count_response <=> int_like).to eq(1)
    end

    it 'returns nil when values are not comparable' do
      expect(count_response <=> :value).to be_nil
    end
  end

  describe 'Comparable operators' do
    it 'supports equality for the same value' do
      expect(count_response == 10).to be(true)
    end

    it 'supports inequality for a different value' do
      expect(count_response == 11).to be(false)
    end

    it 'supports greater than checks' do
      expect(count_response > 9).to be(true)
    end

    it 'supports greater than or equal checks' do
      expect(count_response >= 10).to be(true)
    end

    it 'supports less than checks' do
      expect(count_response < 11).to be(true)
    end

    it 'supports less than or equal checks' do
      expect(count_response <= 10).to be(true)
    end

    it 'supports between? for an enclosing range' do
      expect(count_response.between?(9, 11)).to be(true)
    end

    it 'supports between? for a non-enclosing range' do
      expect(count_response.between?(11, 12)).to be(false)
    end
  end

  describe 'arithmetic operators' do
    it 'supports addition with an integer' do
      expect(count_response + 5).to eq(15)
    end

    it 'supports subtraction with an integer' do
      expect(count_response - 3).to eq(7)
    end

    it 'supports multiplication with an integer' do
      expect(count_response * 2).to eq(20)
    end

    it 'supports division with an integer' do
      expect(count_response / 4).to eq(2)
    end

    it 'returns Integer for integer addition' do
      expect(count_response + 5).to be_a(Integer)
    end

    it 'returns Integer for integer subtraction' do
      expect(count_response - 3).to be_a(Integer)
    end

    it 'returns Integer for integer multiplication' do
      expect(count_response * 2).to be_a(Integer)
    end

    it 'returns Integer for integer division' do
      expect(count_response / 4).to be_a(Integer)
    end

    it 'supports addition with a float' do
      expect(count_response + 0.5).to eq(10.5)
    end

    it 'supports subtraction with a float' do
      expect(count_response - 0.5).to eq(9.5)
    end

    it 'supports multiplication with a float' do
      expect(count_response * 0.5).to eq(5.0)
    end

    it 'supports division with a float' do
      expect(count_response / 4.0).to eq(2.5)
    end

    it 'returns Float for float addition' do
      expect(count_response + 0.5).to be_a(Float)
    end

    it 'returns Float for float subtraction' do
      expect(count_response - 0.5).to be_a(Float)
    end

    it 'returns Float for float multiplication' do
      expect(count_response * 0.5).to be_a(Float)
    end

    it 'returns Float for float division' do
      expect(count_response / 4.0).to be_a(Float)
    end

    it 'supports addition with a to_int object' do
      expect(count_response + int_like).to eq(15)
    end

    it 'supports subtraction with a to_int object' do
      expect(count_response - int_like).to eq(5)
    end

    it 'supports multiplication with a to_int object' do
      expect(count_response * int_like).to eq(50)
    end

    it 'supports division with a to_int object' do
      expect(count_response / int_like).to eq(2)
    end

    it 'supports left-hand addition through Ruby coercion' do
      expect(5 + count_response).to eq(15)
    end

    it 'supports left-hand subtraction through Ruby coercion' do
      expect(5 - count_response).to eq(-5)
    end

    it 'supports left-hand multiplication through Ruby coercion' do
      expect(5 * count_response).to eq(50)
    end

    it 'supports left-hand integer division through Ruby coercion' do
      expect(5 / count_response).to eq(0)
    end

    it 'supports left-hand float division through Ruby coercion' do
      expect(5.0 / count_response).to eq(0.5)
    end

    it 'raises ZeroDivisionError when dividing by zero' do
      expect { count_response / 0 }.to raise_error(ZeroDivisionError)
    end
  end
end
