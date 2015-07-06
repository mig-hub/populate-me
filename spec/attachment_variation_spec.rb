require 'populate_me/attachment'

RSpec.describe PopulateMe::Attachment::Variation do
  subject { described_class.new name, ext, job }
  let(:name) { :thumbnail }
  let(:ext) { :jpg }
  let(:job) { proc{ :expected } }

  shared_examples "Dotted" do
    it "Has its attributes set" do
      expect(subject.name).to eq(name)
      expect(subject.ext).to eq(ext)
      expect(subject.job).to be_instance_of(Proc)
    end
  end

  it_behaves_like "Dotted"

  it "Can call the job" do
    expect(subject.job.call).to eq(:expected)
  end

  context "From Attachment class methods" do

    let(:described_class) { PopulateMe::Attachment }

    describe "::variation" do

      subject { described_class.variation name, ext, job }

      it_behaves_like "Dotted"

      it "Can call the job" do
        expect(subject.job.call).to eq(:expected)
      end

      context "Job is a block" do
        subject {
          described_class.variation(name, ext) do
            :expected_in_block
          end
        }
        it "Can call the job" do
          expect(subject.job.call).to eq(:expected_in_block)
        end
      end

    end

    describe "::image_magick_variation" do

      subject { 
        described_class.image_magick_variation name, ext, convert_string, options 
      }
      let(:convert_string) { "-negate" }
      let(:options) { {} }

      let(:src) { "/path/src.jpg" }
      let(:dst) { "/path/dst.jpg" }

      it_behaves_like "Dotted"

      it "Has a job waiting for src and dst" do
        expect(subject.job.arity).to eq(2)
      end

      it "Triggers a well formed convert job" do
        expect(Kernel).to receive(:system).with("convert \"#{src}\" -strip -interlace Plane #{convert_string} \"#{dst}\"")
        subject.job.call(src,dst)
      end

      context "When strip is off" do
        let(:options) { {strip: false} }
        it "Removes the corresponding command" do
          expect(Kernel).to receive(:system).with("convert \"#{src}\" -interlace Plane #{convert_string} \"#{dst}\"")
          subject.job.call(src,dst)
        end
      end

      context "When progressive jpeg is off" do
        let(:options) { {progressive: false} }
        it "Removes the corresponding command" do
          expect(Kernel).to receive(:system).with("convert \"#{src}\" -strip #{convert_string} \"#{dst}\"")
          subject.job.call(src,dst)
        end
      end

      context "When extention is not jpeg" do
        let(:ext) { :png }
        it "Does not add commands for progressive jpeg" do
          expect(Kernel).to receive(:system).with("convert \"#{src}\" -strip #{convert_string} \"#{dst}\"")
          subject.job.call(src,dst)
        end
      end

    end

  end

end
