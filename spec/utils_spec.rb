require 'spec_helper'

RSpec.describe "DecoMailFilter::Utils" do
  describe ".zipfile_non_encrypted?" do
    subject { DecoMailFilter::Utils.zipfile_non_encrypted? zippath }

    context "non-encrypted" do
      let(:zippath) { File.join __dir__, "test.zip" }
      it { is_expected.to eq true }
    end

    context "encrypted" do
      let(:zippath) { File.join __dir__, "test-encrypted.zip" }
      it { is_expected.to eq false }
    end

    context "1 encrypted file exists" do
      let(:zippath) { File.join __dir__, "test-1-encrypted.zip" }
      it { is_expected.to eq false }
    end
  end

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

  describe ".make_zip_file" do
    before do
      @filedir = Dir.mktmpdir
      @zipdir = Dir.mktmpdir
      @zippath = File.join @zipdir, 'test.zip'
      @password = 'dummypass'
      @invalid_password = 'invalidpass'
      File.open(File.join(@filedir, 'test1.txt'), 'w') { |f| f.puts 'test1' }
      File.open(File.join(@filedir, 'test2.txt'), 'w') { |f| f.puts 'test2' }
    end

    after do
      FileUtils.rm_rf @filedir
      FileUtils.rm_rf @zipdir
    end

    subject { DecoMailFilter::Utils.make_zip_file @filedir, @zippath, @password }

    it "creates a zip file" do
      subject
      expect(File.exist? @zippath).to eq true
    end

    it { expect(@password != @invalid_password).to eq true }

    it "creates a zip file which is encrypted with the password" do
      subject
      expect(DecoMailFilter::Utils.zipfile_encrypted? @zippath).to eq true
    end
  end
end
