require 'spec_helper'

RSpec.describe "DecoMailFilter::Core" do
  describe "#work" do
    test_address = '<test@example.com>'
    test_address_2 = '<test2@example.com>'

    let(:config) { DecoMailFilter::Config.new }
    # let(:filter) { DecoMailFilter::Core.new config = config } # ??? config becomes nil
    let(:filter) { DecoMailFilter::Core.new config }
    let(:mail_after) { filter.work mail_before }

    describe "\"x-mail-filter\" header" do
      subject { MailParser::Message.new(mail).header.raw('x-mail-filter')&.map(&:chomp) }

      let(:mail_before) do
        <<~EOF
        To: #{test_address}
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

    describe "To address" do
      subject { MailParser::Message.new(mail_after).header.raw('to').map(&:chomp) }

      describe "1 To address doesn't change" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to eq [test_address] }
      end

      describe "2 To addresses changes to 1 dummy address" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}, #{test_address_2}
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to eq [DecoMailFilter::DUMMY_MAIL_TO] }
      end

      describe "1 To address and 1 CC address change to 1 dummy address" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}
          Cc: #{test_address_2}
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to eq [DecoMailFilter::DUMMY_MAIL_TO] }
      end
    end

    describe "Cc address" do
      let(:mail_before) do
        <<~EOF
        To: #{test_address}
        Cc: #{test_address_2}
        Subject: Test subject
        Content-type: text/plain
        
        Test body
        EOF
      end

      it { expect(MailParser::Message.new(mail_after).header['cc']).to be_nil }
    end

    describe "To and Cc Addresses when BCC conversion is disabled" do
      let(:config) { DecoMailFilter::Config.new bcc_conversion = false }

      subject { MailParser::Message.new(mail_after).to.map(&:to_s) }

      context "2 To addresses" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}, #{test_address_2}
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to include test_address }
        it { is_expected.to include test_address_2 }
      end

      context "Different domains" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}, <test@another.com>
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to include "<#{DecoMailFilter::DUMMY_MAIL_TO}>" }
        it { is_expected.not_to include test_address }
        it { is_expected.not_to include test_address_2 }
      end

      context "1 To address and 1 Cc address" do
        let(:mail_before) do
          <<~EOF
          To: #{test_address}
          Cc: #{test_address_2}
          Subject: Test subject
          Content-type: text/plain
          
          Test body
          EOF
        end

        it { is_expected.to include test_address }
        it { expect(MailParser::Message.new(mail_after).cc).to eq [] }
      end
    end
  end

  describe "#have_attachment?" do
    let(:filepath) { File.join __dir__, filename }
    let(:mail) { MailParser::Message.new File.read(filepath) }
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
      context { let(:xyz) { '3-2-2' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-3' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-4' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-5' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-10' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-11' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-12' }; it { is_expected.to eq true } }
      context { let(:xyz) { '3-2-13' }; it { is_expected.to eq true } }
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

      context "test.zip" do
        let(:mail) { MailParser::Message.new File.read(File.join(__dir__, "2-1-2.txt")) }
        let(:filename) { "test.zip" }
        it { is_expected.to eq true }
      end

      context "テスト.zip" do
        let(:mail) { MailParser::Message.new File.read(File.join(__dir__, "2-1-10.txt")) }
        let(:filename) { "テスト.zip" }
        it { is_expected.to eq true }
      end
    end

    describe "file body" do
      before do
        @body = File.open(File.join(@dir, filename), 'rb') { |f| break f.read }
        @orig = Base64.decode64(mail.part[1].rawbody)
      end

      context "test.zip" do
        let(:mail) { MailParser::Message.new File.read(File.join(__dir__, "2-1-2.txt")) }
        let(:filename) { "test.zip" }
        it { expect(@body).to eq @orig }
      end

      context "テスト.zip" do
        let(:mail) { MailParser::Message.new File.read(File.join(__dir__, "2-1-10.txt")) }
        let(:filename) { "テスト.zip" }
        it { expect(@body).to eq @orig }
      end
    end
  end

  describe "#make_zip_file" do
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

    subject { DecoMailFilter::Core.new.make_zip_file @filedir, @zippath, @password }

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
