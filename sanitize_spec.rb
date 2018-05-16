require 'rspec'
require_relative 'core'

RSpec.describe "DecoMailFilter" do
  before do
    @stdout_string = DecoMailFilter.work mail
  end

  test_address = 'test@example.com'
  test_address_2 = 'test2@example.com'

  describe "\"x-mail-filter\" header" do
    subject { MailParser::Message.new(mail_for_test).header.raw('x-mail-filter')&.map(&:chomp) }

    let(:mail) do
      <<~EOF
      To: #{test_address}
      Subject: Test subject
      Content-type: text/plain
      
      Test body
      EOF
    end

    describe "Original mail does not have it" do
      let(:mail_for_test) { mail }
      it { is_expected.to be_nil }
    end

    describe "Filtered mail has it" do
      let(:mail_for_test) { @stdout_string }
      it { is_expected.to eq ["DECO Mail Filter"] }
    end
  end

  describe "To address" do
    subject { MailParser::Message.new(@stdout_string).header.raw('to').map(&:chomp) }

    describe "1 To address doesn't change" do
      let(:mail) do
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
      let(:mail) do
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
      let(:mail) do
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
    let(:mail) do
      <<~EOF
      To: #{test_address}
      Cc: #{test_address_2}
      Subject: Test subject
      Content-type: text/plain
      
      Test body
      EOF
    end

    it { expect(MailParser::Message.new(@stdout_string).header['cc']).to be_nil }
  end
end
