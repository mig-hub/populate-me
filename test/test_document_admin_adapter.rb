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

end
