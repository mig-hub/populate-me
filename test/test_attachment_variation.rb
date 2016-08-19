require 'helper'
require 'populate_me/attachment'

describe PopulateMe::Attachment::Variation do

  parallelize_me!

  let(:described_class) { PopulateMe::Attachment::Variation }
  subject { described_class.new attachment_name, ext, job }
  let(:attachment_name) { :thumbnail }
  let(:ext) { :jpg }
  let(:job) { proc{ :expected } }

  def self.it_has_attributes_set
    it 'Has attributes set' do
      assert_equal attachment_name, subject.name
      assert_equal ext, subject.ext
      assert_instance_of Proc, subject.job
    end
  end

  it_has_attributes_set

  it "Can call the job" do
    assert_equal :expected, subject.job.call
  end

  describe "From Attachment class methods" do

    let(:described_class) { PopulateMe::Attachment }

    describe "::variation" do

      subject { described_class.variation attachment_name, ext, job }

      it_has_attributes_set

      it "Can call the job" do
        assert_equal :expected, subject.job.call
      end

      describe "Job is a block" do
        subject {
          described_class.variation(attachment_name, ext) do
            :expected_in_block
          end
        }
        it "Can call the job" do
          assert_equal :expected_in_block, subject.job.call
        end
      end

    end

    describe "::image_magick_variation" do

      subject { 
        described_class.image_magick_variation attachment_name, ext, convert_string, opts 
      }
      let(:convert_string) { "-negate" }
      let(:opts) { {} }

      let(:src) { "/path/src.jpg" }
      let(:dst) { "/path/dst.jpg" }

      it_has_attributes_set

      it "Has a job waiting for src and dst" do
        assert_equal 2, subject.job.arity
      end

      it "Triggers a well formed convert job" do
        assert_receive(Kernel, :system, nil, ["convert \"#{src}\" -strip -interlace Plane #{convert_string} \"#{dst}\""]) do
          subject.job.call(src,dst)
        end
      end

      describe "When strip is off" do
        let(:opts) { {strip: false} }
        it "Removes the corresponding command" do
          assert_receive(Kernel, :system, nil, ["convert \"#{src}\" -interlace Plane #{convert_string} \"#{dst}\""]) do
            subject.job.call(src,dst)
          end
        end
      end

      describe "When progressive jpeg is off" do
        let(:opts) { {progressive: false} }
        it "Removes the corresponding command" do
          assert_receive(Kernel, :system, nil, ["convert \"#{src}\" -strip #{convert_string} \"#{dst}\""]) do
            subject.job.call(src,dst)
          end
        end
      end

      describe "When extention is not jpeg" do
        let(:ext) { :png }
        it "Does not add commands for progressive jpeg" do
          assert_receive(Kernel, :system, nil, ["convert \"#{src}\" -strip #{convert_string} \"#{dst}\""]) do
            subject.job.call(src,dst)
          end
        end
      end

    end

  end

end
