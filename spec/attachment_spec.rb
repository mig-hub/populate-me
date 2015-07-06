require "populate_me/attachment"

RSpec.describe PopulateMe::Attachment do

  subject { PopulateMe::Attachment.new(document, field) }

  let(:document) { double('document') }
  let(:field) { :thumbnail }

  it "Keeps document and field as attributes" do
    expect(subject.document).to eq(document)
    expect(subject.field).to eq(field)
  end

  it "Delegates settings to its class" do
    allow(described_class).to receive(:settings) { :mock_settings }
    expect(subject.settings).to eq(:mock_settings)
  end

  describe "#field_value" do
    it "Gets the field value of its document" do
      allow(document).to receive(field) { :mock_value }
      expect(subject.field_value).to eq(:mock_value)
    end
  end

  describe "#attachee_prefix" do
    it "Returns the dasherized version of its document class" do
      allow(document).to receive(:class) { String }
      allow(PopulateMe::Utils).to receive(:dasherize_class_name).with('String') { :mock_prefix }
      expect(subject.attachee_prefix).to eq(:mock_prefix)
    end
  end

  describe "#location_root" do
    it "Is the settings root" do
      allow(subject).to receive(:settings) { 
        double('settings', root: :mock_root) 
      }
      expect(subject.location_root).to eq(:mock_root)
    end
  end

  describe "#location" do
    it "Combines location root and the field value" do
      allow(subject).to receive(:location_root) { 'mock_root' }
      allow(subject).to receive(:field_value) { 'mock_value' }
      expect(subject.location).to eq(File.join('mock_root','mock_value'))
    end
  end

  describe "#deleteable?" do
    let(:fake) { "attachment.path" }
    let(:setup_stubs) {
      allow(subject).to receive(:field_value) { path }
      allow(PopulateMe::Utils).to receive(:blank?).with(fake) { false }
      allow(PopulateMe::Utils).to receive(:blank?).with('') { true }
      allow(subject).to receive(:location) { location }
      allow(File).to receive(:exist?).with(fake) { true }
      allow(File).to receive(:exist?).with('') { false }
    }
    let(:path) { fake }
    let(:location) { fake }
    context "When there is something to delete" do
      it "is true" do
        setup_stubs
        expect(subject.deletable?).to eq(true)
      end
    end
    context "When field is blank" do
      let(:path) { '' }
      it "is false" do
        setup_stubs
        expect(subject.deletable?).to eq(false)
      end
    end
    context "When the file does not exist" do
      let(:location) { '' }
      it "is false" do
        setup_stubs
        expect(subject.deletable?).to eq(false)
      end
    end
  end

  describe "#delete" do
    it "Performs if deletable" do
      allow(subject).to receive(:deletable?) { true }
      is_expected.to receive(:perform_delete)
      subject.delete
    end
    it "Does not perform if not deletable" do
      allow(subject).to receive(:deletable?) { false }
      is_expected.not_to receive(:perform_delete)
      subject.delete
    end
  end

  describe "#perform_delete" do
    let(:fake_path) { "/path/to/file" }
    it "Deletes the file at self.location" do
      allow(subject).to receive(:location) { fake_path }
      expect(FileUtils).to receive(:rm).with(fake_path)
      subject.perform_delete
    end
  end

  describe "#create" do
    it "Calls delete before performing" do

    end
  end

end

