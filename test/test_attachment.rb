require 'helper'
require "populate_me/attachment"

describe PopulateMe::Attachment do

  parallelize_me!

  subject { PopulateMe::Attachment.new(document, field) }
  let(:described_class) { PopulateMe::Attachment }
  let(:document) { Minitest::Mock.new }
  let(:field) { :thumbnail }

  describe "Kept attributes" do
    let(:document) { Hash.new }
    it "Keeps document and field as attributes" do
      assert_equal document, subject.document
      assert_equal field, subject.field
    end
  end

  it "Delegates settings to its class" do
    described_class.stub(:settings, :mock_settings) do
      assert_equal :mock_settings, subject.settings
    end
  end

  describe "#field_value" do
    it "Gets the field value of its document" do
      document.expect(field, :mock_value)
      assert_equal :mock_value, subject.field_value
      document.verify
    end
  end

  describe "#attachee_prefix" do
    it "Returns the dasherized version of its document class" do
      document.expect(:class, String)
      PopulateMe::Utils.stub(:dasherize_class_name, :mock_prefix, ['String']) do
        assert_equal :mock_prefix, subject.attachee_prefix
      end
    end
  end

  describe "#location_root" do
    it "Is the settings root" do
      settings = Minitest::Mock.new
      settings.expect(:root, :mock_root)
      subject.stub(:settings, settings) do 
        assert_equal :mock_root, subject.location_root
      end
    end
  end

  describe "#location" do
    it "Combines location root and the field value" do
      subject.stub(:location_root, 'mock_root') do
        subject.stub(:field_value, 'mock_value') do
          assert_equal File.join('mock_root','mock_value'), subject.location
        end
      end
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
        assert_receive(subject, :perform_delete, nil, [nil]) do
          subject.delete
        end
      end
    end
    it "Does not perform if not deletable" do
      subject.stub(:deletable?, false) do
        refute_receive(subject, :perform_delete) do
          subject.delete
        end
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

