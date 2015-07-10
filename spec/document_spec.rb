require 'populate_me/document'

module Car
  class RearviewMirror < PopulateMe::Document
    attr_accessor :my_label_field
  end
end

RSpec.describe PopulateMe::Document do
  
  let(:subject_class) { Car::RearviewMirror }
  subject { subject_class.new }

  describe '#inspect' do
    it 'Returns a classic ruby inspect to object with an underlying Hash' do
      test_hash = { a: 1 }
      allow(subject).to receive(:to_h) { test_hash }
      expect(subject.inspect).to eq("#<#{subject_class.name}:#{test_hash.inspect}>")
    end
  end

  describe '#to_s' do
    it 'Delegates to #inspect' do
      allow(subject).to receive(:inspect) { "inspection" }
      expect(subject.to_s).to eq "inspection"
    end
    context "Has a label field" do
      before do
        allow(subject_class).to receive(:label_field) { :my_label_field }
      end
      context "And the field is not blank" do
        it "Delegates to the label_field" do
          allow(subject).to receive(:my_label_field) { 'my label' }
          expect(subject.to_s).to eq 'my label'
        end
      end
      context "And the field is blank" do
        it "Delegates to the #inspect" do
          allow(subject).to receive(:inspect) { "inspection" }.twice
          allow(subject).to receive(:my_label_field) { '' }
          expect(subject.to_s).to eq 'inspection'
          allow(subject).to receive(:my_label_field) { nil }
          expect(subject.to_s).to eq 'inspection'
        end
      end
    end
  end

  describe 'Class' do

    describe '::to_s' do
      it 'Returns a human friendly classname including parent modules' do
        expect(subject_class.to_s).to eq('Car Rearview Mirror')
      end
    end

    describe '::to_s_short' do
      it 'Returns a human friendly classname' do
        expect(subject_class.to_s_short).to eq('Rearview Mirror')
      end
    end

    describe '::cast' do
      before do
        allow(subject_class).to receive(:documents) do 
          [{my_label_field: 'A'},{my_label_field: 'B'}]
        end
      end
      it 'Can return a single object from the block' do
        out = subject_class.cast{ |c| c.documents[0] }
        expect(out.class).to eq subject_class
      end
      it 'Can return a list of objects from the block' do
        out = subject_class.cast{ |c| c.documents }
        expect(out[0].class).to eq subject_class
        expect(out[1].class).to eq subject_class
      end
      context 'The block returns nil' do
        it 'Returns nil as well' do
          expect(subject_class.cast{|c|nil}).to be_nil
        end
      end
      context 'The block does not return the right thing' do
        it 'Raises type error' do
          expect{subject_class.cast{|c|3}}.to raise_error TypeError
        end
      end
      context 'No argument is given to the block' do
        it 'Calls the block in the class context' do
          out = subject_class.cast{ documents }
          expect(out[0].class).to eq subject_class
          expect(out[1].class).to eq subject_class
        end
      end
    end

  end

end

