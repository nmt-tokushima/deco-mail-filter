require 'spec_helper'

domain_1 = 'example.com'
domain_2 = 'another.com'
domain_3 = 'another2.com'
address_1 = '<test1@example.com>'
address_2 = '<test2@example.com>'
address_3 = '<testx@another.com>'
address_4 = '<testx@another2.com>'

mail_1_to = <<EOS
To: #{address_1}
Subject: title
Content-type: text/plain

body
EOS

mail_2_to = <<EOS
To: #{address_1}, #{address_2}
Subject: title
Content-type: text/plain

body
EOS

mail_1_to_1_cc = <<EOS
To: #{address_1}
Cc: #{address_2}
Subject: title
Content-type: text/plain

body
EOS

# mail, 1 to, 1 another domain to
mail_1_to_1_another_to = <<EOS
To: #{address_1}, #{address_3}
Subject: title
Content-type: text/plain

body
EOS

# mail, 1 to, 1 another domain cc
mail_1_to_1_another_cc = <<EOS
To: #{address_1}
Cc: #{address_3}
Subject: title
Content-type: text/plain

body
EOS

# mail, 1 to, 1 another domain to, 1 another domain to
mail_3_different_domains_to = <<EOS
To: #{address_1}, #{address_3}, #{address_4}
Subject: title
Content-type: text/plain

body
EOS

RSpec.describe "DecoMailFilter::Core" do
  describe "#work" do
    let(:config) { DecoMailFilter::Config.new }
    let(:filter) { DecoMailFilter::Core.new config: config }
    let(:mail_before_parsed) { MailParser::Message.new mail_before }
    let(:mail_after) { filter.work mail_before }
    let(:mail_after_parsed) { MailParser::Message.new mail_after }

    describe "To address" do
      let(:to_before) { mail_before_parsed.header.raw('to').map(&:chomp) }
      let(:to_after) { mail_after_parsed.header.raw('to').map(&:chomp) }
      subject { to_after }

      describe "1 To address doesn't change" do
        let(:mail_before) { mail_1_to }
        it { is_expected.to eq to_before }
      end

      describe "2 To addresses changes to 1 dummy address" do
        let(:mail_before) { mail_2_to }
        it { is_expected.to eq [config.bcc_dummy_to] }
      end

      describe "1 To address and 1 another domain to address changes to 1 dummy address" do
        let(:mail_before) { mail_1_to_1_another_to }
        it { is_expected.to eq [config.bcc_dummy_to] }
      end

      describe "1 To address and 1 CC address change to 1 dummy address" do
        let(:mail_before) { mail_1_to_1_cc }
        it { is_expected.to eq [config.bcc_dummy_to] }
      end

      context "BCC conversion is disabled" do
        let(:config) { DecoMailFilter::Config.new bcc_conversion: false }
        describe { let(:mail_before) { mail_1_to };              it { is_expected.to eq to_before } }
        describe { let(:mail_before) { mail_2_to };              it { is_expected.to eq to_before } }
        describe { let(:mail_before) { mail_1_to_1_another_to }; it { is_expected.to eq to_before } }
        describe { let(:mail_before) { mail_1_to_1_cc };         it { is_expected.to eq to_before } }
      end

      context "whitelist contains a domain" do
        let(:config) { DecoMailFilter::Config.new bcc_conversion_whitelist: [domain_1] }
        describe { let(:mail_before) { mail_2_to };             it { is_expected.to eq to_before } }
        describe { let(:mail_before) { mail_1_to_1_cc };        it { is_expected.to eq to_before } }
        describe { let(:mail_before) { mail_1_to_1_another_to}; it { is_expected.to eq [config.bcc_dummy_to] } }
        describe { let(:mail_before) { mail_1_to_1_another_cc}; it { is_expected.to eq [config.bcc_dummy_to] } }

        context "whitelist contains 2 domains" do
          let(:config) { DecoMailFilter::Config.new bcc_conversion_whitelist: [domain_1, domain_2] }
          describe { let(:mail_before) { mail_2_to };                   it { is_expected.to eq to_before } }
          describe { let(:mail_before) { mail_3_different_domains_to }; it { is_expected.to eq [config.bcc_dummy_to] } }
        end
      end
    end

    describe "Cc address" do
      let(:mail_before) { mail_1_to_1_cc }
      subject { mail_after_parsed.header['cc'] }
      it { is_expected.to be_nil }

      context "BCC conversion is disabled" do
        let(:config) { DecoMailFilter::Config.new bcc_conversion: false }
        let(:cc_before) { mail_before_parsed.header['cc'].first.map(&:to_s) }
        subject { mail_after_parsed.header['cc'].first.map(&:to_s) }
        describe { let(:mail_before) { mail_1_to_1_cc }; it { is_expected.to eq cc_before } }
      end
    end
  end
end
