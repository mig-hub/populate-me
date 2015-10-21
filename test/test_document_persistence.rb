require 'helper'
require 'populate_me/document'

class Stuborn < PopulateMe::Document
  attr_accessor :age
end

describe PopulateMe::Document, 'Persistence' do

  parallelize_me!

  let(:subject_class) { Stuborn }
  subject { subject_class.new }

  describe '::is_unique' do

    before do
      Stuborn.documents = []
    end

    # def doc_doesnt_exist
    #   subject_class.stub(:admin_get, nil) do
    #     yield
    #   end
    # end
    # def doc_exists
    #   subject_class.stub(:admin_get, subject) do
    #     yield
    #   end
    # end

    describe 'The document does not exist yet' do
      it 'Saves an entry with the ID `unique` by default' do
        Stuborn.is_unique
        _(Stuborn.documents.count).must_equal 1
        _(Stuborn.documents[0]['id']).must_equal 'unique'
      end
      it 'Saves an entry with a provided ID' do
        Stuborn.is_unique('provided_id')
        _(Stuborn.documents.count).must_equal 1
        _(Stuborn.documents[0]['id']).must_equal 'provided_id'
      end
    end
    describe 'The document already exist' do
      it 'Does not create a new document and preserve the current one' do
        doc = Stuborn.new({'id'=>'unique', 'age'=>4})
        doc.save
        Stuborn.is_unique
        _(Stuborn.documents.count).must_equal 1
        _(Stuborn.documents[0]).must_equal doc.to_h
      end
    end
  end

end

