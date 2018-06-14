require 'spec_helper'

RSpec.describe "DecoMailFilter::Core" do
  describe "#work" do
    test_address = '<test@example.com>'
    test_address_2 = '<test2@example.com>'

    let(:config) { DecoMailFilter::Config.new }
    let(:filter) { DecoMailFilter::Core.new config: config }
    let(:mail_after) { filter.work mail_before }

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

        it { is_expected.to eq [config.bcc_dummy_to] }
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

        it { is_expected.to eq [config.bcc_dummy_to] }
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
      let(:config) { DecoMailFilter::Config.new bcc_conversion: false }

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

        it { pending; is_expected.to include "<#{DecoMailFilter::DUMMY_MAIL_TO}>" }
        it { pending; is_expected.not_to include test_address }
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
end
