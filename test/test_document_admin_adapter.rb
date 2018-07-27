require 'helper'
require 'populate_me/document'
require 'populate_me/attachment'

describe PopulateMe::Document, 'AdminAdapter' do

  parallelize_me!

  describe '::admin_image_field' do
    describe 'When there is no image' do
      class AdaptedNoImage < PopulateMe::Document
        field :name
      end
      it 'Returns nil' do
        assert_nil AdaptedNoImage.admin_image_field
      end
    end
    describe 'When there is an image but not with the right variation' do
      class AdaptedImageNoVar < PopulateMe::Document
        field :name
        field :thumbnail1, type: :attachment, class_name: PopulateMe::Attachment
        field :thumbnail2, type: :attachment, variations:[
          PopulateMe::Variation.new_image_magick_job(:small,:jpg,'-negate')
        ], class_name: PopulateMe::Attachment
      end
      it 'Returns nil' do
        assert_nil AdaptedImageNoVar.admin_image_field
      end
    end
    describe 'When there is an image and the right variation' do
      class AdaptedImageVar < PopulateMe::Document
        field :name
        field :thumbnail1, type: :attachment, class_name: PopulateMe::Attachment
        field :thumbnail2, type: :attachment, variations:[
          PopulateMe::Variation.new_image_magick_job(:populate_me_thumb,:jpg,'-negate')
        ], class_name: PopulateMe::Attachment
      end
      it 'Returns the field' do
        assert_equal :thumbnail2, AdaptedImageVar.admin_image_field
      end
    end
  end

  describe '::to_admin_list' do
    class PolyAdapted < PopulateMe::Document
      polymorphic values: ['Shape 1', 'Shape 2']
    end
    class NotPolyAdapted < PopulateMe::Document
    end
    it 'Contains polymorphic_type values and predicate if polymorphic' do
      assert PolyAdapted.to_admin_list[:is_polymorphic]
      assert_equal ['Shape 1', 'Shape 2'], PolyAdapted.to_admin_list[:polymorphic_type_values]
      refute NotPolyAdapted.to_admin_list[:is_polymorphic]
      assert_nil NotPolyAdapted.to_admin_list[:polymorphic_type_values]
    end
  end

  describe '#to_admin_list_item' do
    class ContentTitle < PopulateMe::Document
      field :content
    end
    class PolyListItem < PopulateMe::Document
      field :name
      relationship :images, only_for: 'Slider'
      relationship :paragraphs, only_for: 'Chapter'
    end
    it 'Sets ID as a string version' do
      doc = ContentTitle.new id: 3
      assert_equal '3', doc.to_admin_list_item[:id]
    end
    describe 'When title is long' do
      it 'Is truncated' do
        doc = ContentTitle.new
        doc.content = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        title = doc.to_admin_list_item[:title]
        refute_equal doc.content, title
        assert_match title.sub(/\.\.\.$/, ''), doc.content 
        assert_operator title.length, :<=, doc.content.length 
      end
    end
    describe 'When title is short enough' do
      it 'Does not truncate' do
        doc = ContentTitle.new
        doc.content = 'Hello'
        title = doc.to_admin_list_item[:title]
        assert_equal doc.content, title
      end
    end
    describe 'Polymorphism' do
      it 'Only keeps in the local menu applicable relationships' do
        doc = PolyListItem.new(polymorphic_type: 'Slider')
        list_item = doc.to_admin_list_item request: Struct.new(:script_name).new('/admin')
        assert_equal 1, list_item[:local_menu].size
        assert_equal 'Images', list_item[:local_menu][0][:title]
      end
    end
  end

  describe '::admin_find ::admin_find_first' do
    
    class FindablePerson < PopulateMe::Document
      field :first_name
      field :last_name
    end
    
    before do
      FindablePerson.documents = []
      FindablePerson.new(first_name: 'Bobby', last_name: 'Peru').save
      FindablePerson.new(first_name: 'John', last_name: 'Doe').save
      FindablePerson.new(first_name: 'John', last_name: 'Turturo').save
    end

    it 'Finds everything' do
      people = FindablePerson.admin_find
      assert_equal Array, people.class
      assert_equal 3, people.size
      assert_equal FindablePerson.documents, people
    end

    it 'Finds with query' do
      people = FindablePerson.admin_find query: {first_name: 'John'}
      assert_equal Array, people.class
      assert_equal 2, people.size
      assert_equal 'Doe', people[0].last_name
    end

    it 'Finds first' do
      person = FindablePerson.admin_find_first
      assert_equal 'Bobby', person.first_name
    end

    it 'Finds first with query' do
      person = FindablePerson.admin_find_first query: {first_name: 'John'}
      assert_equal 'Doe', person.last_name
    end

  end

  describe '::admin_distinct' do

    class Distinction < PopulateMe::Document
      attr_accessor :title, :age
    end

    before do
      Distinction.documents = []
    end

    it 'Can list all distinct values' do
      Distinction.new(title: 'Lord').save
      Distinction.new(title: 'Lord').save
      Distinction.new.save
      Distinction.new(title: 'Chevalier').save
      Distinction.new(title: 'Baron').save
      Distinction.new(title: 'Baron').save
      result = Distinction.admin_distinct :title
      assert_instance_of Array, result
      assert_equal 3, result.size
      assert_includes result, 'Lord'
      assert_includes result, 'Chevalier'
      assert_includes result, 'Baron'
    end

    it 'Can list all distinct values for a specific selector' do
      Distinction.new(title: 'Chevalier', age: 33).save
      Distinction.new(title: 'Chevalier', age: 34).save
      Distinction.new(title: 'Baron', age: 35).save
      Distinction.new(title: 'Baron', age: 36).save
      result = Distinction.admin_distinct :age, query: {title: 'Baron'}
      assert_instance_of Array, result
      assert_equal 2, result.size
      assert_includes result, 35
      assert_includes result, 36
    end

  end

  describe '#to_admin_form' do
    class PolyForm < PopulateMe::Document
      field :name
      field :image, only_for: 'Image'
      field :title, only_for: 'Article'
      field :content, only_for: 'Article'
      field :position
    end
    class NotPolyForm < PopulateMe::Document
      field :name
    end
    it 'Only has fields for the current polymorphic type' do
      obj = PolyForm.new polymorphic_type: 'Article'
      form = obj.to_admin_form
      assert_nil form[:fields].find{|f| f[:field_name]==:image}
      refute_nil form[:fields].find{|f| f[:field_name]==:title}
      refute_nil form[:fields].find{|f| f[:field_name]==:content}
    end
    it 'Works when not polymorphic' do
      obj = NotPolyForm.new
      form = obj.to_admin_form
      refute_nil form[:fields].find{|f| f[:field_name]==:name}
    end
  end

end

