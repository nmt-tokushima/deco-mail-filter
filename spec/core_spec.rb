require 'spec_helper'
require 'kconv'

RSpec.describe "DecoMailFilter::Core" do
  describe "#work" do
    let(:config) { DecoMailFilter::Config.new }
    let(:filter) { DecoMailFilter::Core.new config: config }
    let(:mail_after) { filter.work mail_before }

    describe "\"x-mail-filter\" header" do
      subject { MailParser::Message.new(mail).header.raw('x-mail-filter')&.map(&:chomp) }

      let(:mail_before) do
        <<~EOF
        To: <test@example.com>
        Subject: Test subject
        Content-type: text/plain
        
        Test body
        EOF
      end

      describe "Original mail does not have it" do
        let(:mail) { mail_before }
        it { is_expected.to be_nil }
      end

      describe "Filtered mail has it" do
        let(:mail) { mail_after }
        it { is_expected.to eq ["DECO Mail Filter"] }
      end
    end
  end

  describe "#attachment_parts" do
    let(:mail) { MailParser::Message.new read_mail filename }

    context "has no attachment part" do
      let(:filename) { "#{xy}-1.txt" }
      subject { DecoMailFilter::Core.new.attachment_parts(mail).empty? }

      context { let(:xy) { '1-1' }; it { is_expected.to eq true } }
      context { let(:xy) { '1-2' }; it { is_expected.to eq true } }
      context { let(:xy) { '2-1' }; it { is_expected.to eq true } }
      context { let(:xy) { '2-2' }; it { is_expected.to eq true } }
      context { let(:xy) { '3-1' }; it { is_expected.to eq true } }
      context { let(:xy) { '3-2' }; it { is_expected.to eq true } }
    end

    context "has 1 attachment part" do
      let(:filename) { "#{xyz}.txt" }
      subject { DecoMailFilter::Core.new.attachment_parts(mail) }

      context { let(:xyz) { '1-1-2' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '1-1-5' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '1-1-5' }; it { is_expected.to include mail.part[2] } }
      context { let(:xyz) { '2-1-2' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '2-1-5' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '2-1-5' }; it { is_expected.to include mail.part[2] } }

      context { let(:xyz) { '3-1-2' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-3' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-4' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-5' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-5' }; it { is_expected.to include mail.part[2] } }

      context { let(:xyz) { '3-1-10' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-11' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-12' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-13' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-13' }; it { is_expected.to include mail.part[2] } }
      context { let(:xyz) { '3-1-14' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-15' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-16' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-1-17' }; it { is_expected.to include mail.part[1] } }

      context { let(:xyz) { '3-2-2' }; it { is_expected.to include mail.part[1] } }
      context { let(:xyz) { '3-2-10' }; it { is_expected.to include mail.part[1] } }

      describe 'Special cases for Joruri Mail' do
        context { let(:xyz) { '3-2-3' }; it { is_expected.to include mail.part[0] } }
        context { let(:xyz) { '3-2-4' }; it { is_expected.to include mail.part[0] } }
        context { let(:xyz) { '3-2-5' }; it { is_expected.to include mail.part[0] } } # test.txt
        context { let(:xyz) { '3-2-5' }; it { is_expected.to include mail.part[2] } } # text.zip
        context { let(:xyz) { '3-2-11' }; it { is_expected.to include mail.part[0] } } # テスト.txt
        context { let(:xyz) { '3-2-12' }; it { is_expected.to include mail.part[0] } } # テスト.html
        context { let(:xyz) { '3-2-13' }; it { is_expected.to include mail.part[0] } } # テスト.txt
        context { let(:xyz) { '3-2-13' }; it { is_expected.to include mail.part[2] } } # テスト.zip
        context { let(:xyz) { '3-2-14' }; it { is_expected.to include mail.part[0] } } # test-ja.txt
        context { let(:xyz) { '3-2-15' }; it { is_expected.to include mail.part[0] } } # test-ja-sjis.txt
        context { let(:xyz) { '3-2-16' }; it { is_expected.to include mail.part[0] } } # テスト-ja.txt
        context { let(:xyz) { '3-2-17' }; it { is_expected.to include mail.part[0] } } # テスト-ja-sjis.txt
      end
    end
  end

  describe "#have_attachment?" do
    let(:mail) { MailParser::Message.new read_mail filename }
    subject { DecoMailFilter::Core.new.have_attachment? mail }

    context "X-Y-1" do
      let(:filename) { "#{xy}-1.txt" }
      context { let(:xy) { '1-1' }; it { is_expected.to eq false } }
      context { let(:xy) { '1-2' }; it { is_expected.to eq false } }
      context { let(:xy) { '2-1' }; it { is_expected.to eq false } }
      context { let(:xy) { '2-2' }; it { is_expected.to eq false } }
      context { let(:xy) { '3-1' }; it { is_expected.to eq false } }
      context { let(:xy) { '3-2' }; it { is_expected.to eq false } }
    end

    context "X-Y-(not 1)" do
      let(:filename) { "#{xyz}.txt" }
      context { let(:xyz) { '1-1-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-1-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-1-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-1-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-2-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-2-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-2-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '1-2-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-10' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-11' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-12' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-1-13' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-10' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-11' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-12' }; it { is_expected.to eq true } }
      context { let(:xyz) { '2-2-13' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-10' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-11' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-12' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-13' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-14' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-15' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-1-16' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-10' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-11' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-12' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-13' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-14' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-15' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-16' }; it { is_expected.to eq true } }
    end
  end

  describe "#write_attachments" do
    before do
      @dir = Dir.mktmpdir
      DecoMailFilter::Core.new.write_attachments mail, @dir
    end
    after { FileUtils.rm_rf @dir }

    describe "file existence" do
      subject { File.exist? File.join @dir, filename }

      context { let(:mail) { MailParser::Message.new read_mail "2-1-2.txt" };  let(:filename) { "test.zip" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "2-1-3.txt" };  let(:filename) { "test.txt" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "2-1-10.txt" }; let(:filename) { "テスト.zip".tosjis }; it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "2-2-2.txt" };  let(:filename) { "test.zip" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "2-2-3.txt" };  let(:filename) { "test.txt" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "2-2-10.txt" }; let(:filename) { "テスト.zip".tosjis }; it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-1-2.txt" };  let(:filename) { "test.zip" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-1-3.txt" };  let(:filename) { "test.txt" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-1-10.txt" }; let(:filename) { "テスト.zip".tosjis }; it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-2-2.txt" };  let(:filename) { "test.zip" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-2-3.txt" };  let(:filename) { "test.txt" };          it { is_expected.to eq true } }
      context { let(:mail) { MailParser::Message.new read_mail "3-2-10.txt" }; let(:filename) { "テスト.zip".tosjis }; it { is_expected.to eq true } }
    end

    describe "file body" do
      context "binary file" do
        before do
          @body = File.open(File.join(@dir, filename), 'rb') { |f| break f.read }
          @orig = Base64.decode64(mail.part[1].rawbody)
        end

        context "test.zip 2-1" do
          let(:mail) { MailParser::Message.new read_mail "2-1-2.txt" }
          let(:filename) { "test.zip" }
          it { expect(@body).to eq @orig }
        end

        context "test.zip 3-1" do
          let(:mail) { MailParser::Message.new read_mail "3-1-2.txt" }
          let(:filename) { "test.zip" }
          it { expect(@body).to eq @orig }
        end

        context "テスト.zip 2-1" do
          let(:mail) { MailParser::Message.new read_mail "2-1-10.txt" }
          let(:filename) { "テスト.zip".tosjis }
          it { expect(@body).to eq @orig }
        end

        context "テスト.zip 3-1" do
          let(:mail) { MailParser::Message.new read_mail "3-1-10.txt" }
          let(:filename) { "テスト.zip".tosjis }
          it { expect(@body).to eq @orig }
        end
      end

      context "text file" do
        before do
          @body = File.open(File.join(@dir, filename), 'r') { |f| break f.read }
          @orig = mail.part[1].body
        end

        context "test.txt 2-1" do
          let(:mail) { MailParser::Message.new read_mail "2-1-3.txt" }
          let(:filename) { "test.txt" }
          it { expect(@body).to eq @orig }
        end

        context "test.txt 3-1" do
          let(:mail) { MailParser::Message.new read_mail "3-1-3.txt" }
          let(:filename) { "test.txt" }
          it { expect(@body).to eq @orig }
        end
      end
    end
  end

  describe "#attachment_filenames" do
    subject { DecoMailFilter::Core.new.attachment_filenames mail }

    context "nothing" do
      let(:mail) { MailParser::Message.new read_mail "2-1-1.txt" }
      it { is_expected.to eq [] }
    end

    context "test.zip" do
      let(:mail) { MailParser::Message.new read_mail "2-1-2.txt" }
      it { is_expected.to eq ["test.zip"] }
    end

    context "test.txt, test.zip" do
      let(:mail) { MailParser::Message.new read_mail "2-1-5.txt" }
      it { is_expected.to eq ["test.txt", "test.zip"] }
    end

    context "テスト.txt, テスト.zip" do
      let(:mail) { MailParser::Message.new read_mail "2-1-13.txt" }
      it { is_expected.to eq ["テスト.txt".tosjis, "テスト.zip".tosjis] }
    end
  end
end
