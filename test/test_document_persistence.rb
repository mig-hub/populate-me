require 'helper'
require 'populate_me/document'

class Stuborn < PopulateMe::Document
end

describe PopulateMe::Document, 'Persistence' do

  parallelize_me!

  let(:subject_class) { Stuborn }
  subject { subject_class.new }

  describe '::is_unique' do

    def doc_doesnt_exist
      subject_class.stub(:admin_get, nil) do
        yield
      end
    end
    def doc_exists
      subject_class.stub(:admin_get, subject) do
        yield
      end
    end

    describe 'The document does not exist yet' do
      it 'Saves an entry with the ID unique' do
        doc_doesnt_exist do
          # expect_any_instance_of(subject_class).to receive(:set_from_hash).with({id:'unique'}) { subject }
          # expect_any_instance_of(subject_class).to receive(:perform_create)
          # subject_class.is_unique
          assert_any_receive(subject_class, :set_from_hash, subject, [{id:'unique'}]) do
            assert_any_receive(subject_class, :perform_create) do
              subject_class.is_unique
            end
          end
        end
      end
      it 'Can save an entry with a different ID' do
        doc_doesnt_exist do
          expect_any_instance_of(subject_class).to receive(:set_from_hash).with({id:'different_id'}) { subject }
          expect_any_instance_of(subject_class).to receive(:perform_create)
          subject_class.is_unique('different_id')
        end
      end
    end
    describe 'The document already exist' do
      it 'Does not modify the existing document' do
        doc_exists do
          expect_any_instance_of(subject_class).not_to receive(:perform_update)
          subject_class.is_unique
        end
      end
      it 'Does not create a new document' do
        doc_exists do
          expect_any_instance_of(subject_class).not_to receive(:perform_create)
          subject_class.is_unique
        end
      end
    end
  end

end

