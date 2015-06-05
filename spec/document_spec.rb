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
        expect(Car::RearviewMirror.to_s).to eq('Car Rearview Mirror')
      end
    end

    describe '::to_s_short' do
      it 'Returns a human friendly classname' do
        expect(Car::RearviewMirror.to_s_short).to eq('Rearview Mirror')
      end
    end

  end

end

