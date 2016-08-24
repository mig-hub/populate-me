require 'helper'
require 'populate_me/attachment'
require 'populate_me/document'

describe PopulateMe::Attachment do

  parallelize_me!

  class NiceAttachment < PopulateMe::Attachment
    set :url_prefix, '/under'
  end

  class NiceIllustration < PopulateMe::Document
    set :default_attachment_class, NiceAttachment
    field :name
    field :image, type: :attachment, variations: [
      PopulateMe::Variation.new_image_magick_job(:negated, :jpg, '-negate'),
      PopulateMe::Variation.new_image_magick_job(:negated_gif, :gif, '-negate')
    ]
  end

  subject { NiceAttachment.new(document, field) }
  let(:described_class) { NiceAttachment }
  let(:document) { NiceIllustration.new(name: 'Painting', image: 'myimage.jpg') }
  let(:field) { :image }

  describe "Kept attributes" do
    it "Keeps document and field as attributes" do
      assert_equal document, subject.document
      assert_equal field, subject.field
    end
  end

  it "Delegates settings to its class" do
    assert_equal '/under', described_class.settings.url_prefix
    assert_equal '/under', subject.settings.url_prefix
  end

  describe "#field_value" do
    it "Gets the field value of its document" do
      assert_equal 'myimage.jpg', subject.field_value
    end
  end

  describe "#variations" do
    it "Gets variations for the field" do
      variations = subject.variations
      assert_equal 2, variations.size
      assert_equal :negated, variations[0].name
    end
  end

  describe "#attachee_prefix" do
    it "Returns the dasherized version of its document class" do
      assert_equal 'nice-illustration', subject.attachee_prefix
    end
  end

  describe "#location_root" do
    it "It concatenates the root, url_prefix and class name dasherized" do
      assert_equal "#{subject.settings.root}/under/nice-illustration", subject.location_root
    end
  end

  describe "#location" do
    it "Combines location root and the field value" do
      assert_equal "#{subject.location_root}/myimage.jpg", subject.location
    end
  end

  describe "#deletable?" do
    let(:fake) { File.expand_path(__FILE__) }
    def setup_stubs
      subject.stub(:field_value, path) do
        subject.stub(:location, loc) do
          yield
        end
      end
    end
    let(:path) { fake }
    let(:loc) { fake }
    describe "When there is something to delete" do
      it "is true" do
        setup_stubs do
          assert subject.deletable?
        end
      end
    end
    describe "When field is blank" do
      let(:path) { '' }
      it "is false" do
        setup_stubs do
          refute subject.deletable?
        end
      end
    end
    describe "When the file does not exist" do
      let(:loc) { 'non-existing.path' }
      it "is false" do
        setup_stubs do
          refute subject.deletable?
        end
      end
    end
  end

  describe "#delete" do
    it "Performs if deletable" do
      subject.stub(:deletable?, true) do
        assert_receive(subject, :perform_delete, nil, [:negated]) do
          subject.delete(:negated)
        end
      end
    end
    it "Does not perform if not deletable" do
      subject.stub(:deletable?, false) do
        refute_receive(subject, :perform_delete) do
          subject.delete(:thumb)
        end
      end
    end
    it "Can delete all variations in one go" do
      # Most used
      subject.stub(:deletable?, true) do
        mocked_meth = Minitest::Mock.new
        mocked_meth.expect(:call, nil, [:original])
        mocked_meth.expect(:call, nil, [:negated])
        mocked_meth.expect(:call, nil, [:negated_gif])
        subject.stub :perform_delete, mocked_meth do
          subject.delete_all
        end
        assert mocked_meth.verify, "Expected #{subject.inspect} to call :perform_delete for all variations."
      end
    end
  end

  describe "#perform_delete" do
    let(:fake_path) { "/path/to/file" }
    it "Deletes the file at self.location" do
      subject.stub(:location, fake_path) do
        assert_receive(FileUtils, :rm, nil, [fake_path]) do
          subject.perform_delete
        end
      end
    end
  end

  describe "#create" do
    it "Calls delete before performing" do

    end
  end

end

