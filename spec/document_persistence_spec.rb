require 'populate_me/document'

class Stuborn < PopulateMe::Document
end

RSpec.describe PopulateMe::Document, 'Persistence' do

  let(:subject_class) { Stuborn }
  subject { subject_class.new }

  describe '::is_unique' do
    context 'The document does not exist yet' do
      before do
        allow(subject_class).to receive(:admin_get) { nil }
      end
      it 'Saves an entry with the ID unique' do
        expect_any_instance_of(subject_class).to receive(:set_from_hash).with({id:'unique'}) { subject }
        expect_any_instance_of(subject_class).to receive(:perform_create)
        subject_class.is_unique
      end
      it 'Can save an entry with a different ID' do
        expect_any_instance_of(subject_class).to receive(:set_from_hash).with({id:'different_id'}) { subject }
        expect_any_instance_of(subject_class).to receive(:perform_create)
        subject_class.is_unique('different_id')
      end
    end
    context 'The document already exist' do
      before do
        allow(subject_class).to receive(:admin_get) { subject }
      end
      it 'Does not modify the existing document' do
        expect_any_instance_of(subject_class).not_to receive(:perform_update)
        subject_class.is_unique
      end
      it 'Does not create a new document' do
        expect_any_instance_of(subject_class).not_to receive(:perform_create)
        subject_class.is_unique
      end
    end
  end

end

