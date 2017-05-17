require 'helper'
require 'populate_me/document'

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

  describe '#to_admin_list_item' do
    class ContentTitle < PopulateMe::Document
      field :content
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
  end

end
