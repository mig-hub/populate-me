require 'helper'
require 'populate_me/document'

module Car
  class RearviewMirror < PopulateMe::Document
    attr_accessor :my_label_field
  end
end

describe PopulateMe::Document do
  
  parallelize_me!

  let(:subject_class) { Car::RearviewMirror }
  subject { subject_class.new }

  describe '#inspect' do
    it 'Returns a classic ruby inspect to object with an underlying Hash' do
      test_hash = { a: 1 }
      subject.stub(:to_h, test_hash) do
        _(subject.inspect).must_equal("#<#{subject_class.name}:#{test_hash.inspect}>")
      end
    end
  end

  describe '#to_s' do
    it 'Delegates to #inspect' do
      subject.stub :inspect, "inspection" do
        _(subject.to_s).must_equal "inspection"
      end
    end
    describe "Has a label field" do
      describe "And the field is not blank" do
        it "Delegates to the label_field" do
          subject_class.stub :label_field, :my_label_field do
            subject.stub :my_label_field, 'my label' do
              _(subject.to_s).must_equal 'my label'
            end
          end
        end
      end
      describe "And the field is blank" do
        it "Delegates to the #inspect" do
          subject_class.stub :label_field, :my_label_field do
            subject.stub :inspect, "inspection" do
              subject.stub :my_label_field, '' do
                _(subject.to_s).must_equal 'inspection'
              end
              subject.stub :my_label_field, nil do
                _(subject.to_s).must_equal 'inspection'
              end
            end
          end
        end
      end
    end
  end

  describe 'Class' do

    describe '::to_s' do
      it 'Returns a human friendly classname including parent modules' do
        _(subject_class.to_s).must_equal('Car Rearview Mirror')
      end
    end

    describe '::to_s_short' do
      it 'Returns a human friendly classname' do
        _(subject_class.to_s_short).must_equal('Rearview Mirror')
      end
    end

    describe '::cast' do
      let(:docs) do
        [{my_label_field: 'A'},{my_label_field: 'B'}]
      end
      it 'Can return a single object from the block' do
        subject_class.stub :documents, docs do 
          out = subject_class.cast{ |c| c.documents[0] }
          _(out.class).must_equal subject_class
        end
      end
      it 'Can return a list of objects from the block' do
        subject_class.stub :documents, docs do 
          out = subject_class.cast{ |c| c.documents }
          _(out[0].class).must_equal subject_class
          _(out[1].class).must_equal subject_class
        end
      end
      describe 'The block returns nil' do
        it 'Returns nil as well' do
          subject_class.stub :documents, docs do 
            _(subject_class.cast{|c|nil}).must_be_nil
          end
        end
      end
      describe 'The block does not return the right thing' do
        it 'Raises type error' do
          subject_class.stub :documents, docs do 
            _{subject_class.cast{|c|3}}.must_raise TypeError
          end
        end
      end
      describe 'No argument is given to the block' do
        it 'Calls the block in the class context' do
          subject_class.stub :documents, docs do 
            out = subject_class.cast{ documents }
            _(out[0].class).must_equal subject_class
            _(out[1].class).must_equal subject_class
          end
        end
      end
    end

  end

end

