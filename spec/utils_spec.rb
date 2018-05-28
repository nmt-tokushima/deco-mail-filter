require 'spec_helper'

RSpec.describe "DecoMailFilter::Utils" do
  describe ".zipfile_encrypted?" do
    subject { DecoMailFilter::Utils.zipfile_encrypted? zippath }

    context "encrypted" do
      let(:zippath) { File.join __dir__, "test-encrypted.zip" }
      it { is_expected.to eq true }
    end

    context "not encrypted" do
      let(:zippath) { File.join __dir__, "test.zip" }
      it { is_expected.to eq false }
    end
  end
end
