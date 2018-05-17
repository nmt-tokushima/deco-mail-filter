require 'rspec'
require_relative 'core'

RSpec.describe "DecoMailFilter" do
  test_address = '<test@example.com>'
  test_address_2 = '<test2@example.com>'

  let(:filter) { DecoMailFilter.new }
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
    subject { MailParser::Message.new(mail_after).to.map(&:to_s) }

    let(:filter) { DecoMailFilter.new bcc_conversion = false }

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
