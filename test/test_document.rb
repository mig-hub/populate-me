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
        assert_equal "#<#{subject_class.name}:#{test_hash.inspect}>", subject.inspect
      end
    end
  end

  describe '#to_s' do
    it 'Delegates to #inspect' do
      subject.stub :inspect, "inspection" do
        assert_equal "inspection", subject.to_s
      end
    end
    describe "Has a label field" do
      describe "And the field is not blank" do
        it "Delegates to the label_field" do
          subject_class.stub :label_field, :my_label_field do
            subject.stub :my_label_field, 'my label' do
              assert_equal 'my label', subject.to_s
            end
          end
        end
        it 'Does not pass a reference that can be modified' do
          subject_class.stub :label_field, :my_label_field do
            subject.stub :my_label_field, 'my label' do
              assert_equal 'my label', subject.to_s
              var = subject.to_s
              var << 'BOOM'
              assert_equal 'my label', subject.to_s
            end
          end
        end
      end
      describe "And the field is blank" do
        it "Delegates to the #inspect" do
          subject_class.stub :label_field, :my_label_field do
            subject.stub :inspect, "inspection" do
              subject.stub :my_label_field, '' do
                assert_equal 'inspection', subject.to_s
              end
              subject.stub :my_label_field, nil do
                assert_equal 'inspection', subject.to_s
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
        assert_equal 'Car Rearview Mirror', subject_class.to_s
      end
    end

    describe '::to_s_short' do
      it 'Returns a human friendly classname' do
        assert_equal 'Rearview Mirror', subject_class.to_s_short
      end
    end

    describe '::cast' do
      let(:docs) do
        [{my_label_field: 'A'},{my_label_field: 'B'}]
      end
      it 'Can return a single object from the block' do
        subject_class.stub :documents, docs do 
          out = subject_class.cast{ |c| c.documents[0] }
          assert_equal subject_class, out.class
        end
      end
      it 'Can return a list of objects from the block' do
        subject_class.stub :documents, docs do 
          out = subject_class.cast{ |c| c.documents }
          assert_equal subject_class, out[0].class
          assert_equal subject_class, out[1].class
        end
      end
      describe 'The block returns nil' do
        it 'Returns nil as well' do
          subject_class.stub :documents, docs do 
            assert_nil subject_class.cast{|c|nil}
          end
        end
      end
      describe 'The block does not return the right thing' do
        it 'Raises type error' do
          subject_class.stub :documents, docs do 
            assert_raises(TypeError) do
              subject_class.cast{|c|3}
            end
          end
        end
      end
      describe 'No argument is given to the block' do
        it 'Calls the block in the class context' do
          subject_class.stub :documents, docs do 
            out = subject_class.cast{ documents }
            assert_equal subject_class, out[0].class
            assert_equal subject_class, out[1].class
          end
        end
      end
    end

  end

end

