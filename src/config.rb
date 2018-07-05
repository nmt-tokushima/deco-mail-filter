require 'open-uri'
require 'json'

module DecoMailFilter
  class Config
    DEFAULT_DUMMY_TO = 'bcc@deco-project.org'

    ENCODING_BASE64 = 1
    ENCODING_QUOTED_PRINTABLE = 2

    attr_reader(
      :bcc_conversion,
      :bcc_dummy_to,
      :bcc_conversion_disable_domains,
      :attachments_encryption,
      :attachments_encryption_password_length,
      :attachments_encryption_subject,
      :attachments_encryption_additional_text,
      :attachments_encryption_encoding,
      :attachments_encryption_password_notification,
      :attachments_encryption_disable_emails,
      :attachments_encryption_disable_domain_froms,
      :attachments_encryption_disable_domain_tos
    )

    def initialize(
      bcc_conversion: true,
      bcc_dummy_to: DEFAULT_DUMMY_TO,
      bcc_conversion_disable_domains: [],
      attachments_encryption: false,
      attachments_encryption_password_length: 8,
      attachments_encryption_subject: '',
      attachments_encryption_additional_text: '',
      attachments_encryption_encoding: ENCODING_BASE64,
      attachments_encryption_password_notification: false,
      attachments_encryption_disable_emails: [],
      attachments_encryption_disable_domain_froms: [],
      attachments_encryption_disable_domain_tos: []
    )
      @bcc_conversion = bcc_conversion
      @bcc_dummy_to = bcc_dummy_to
      @bcc_conversion_disable_domains = bcc_conversion_disable_domains
      @attachments_encryption = attachments_encryption
    end

    def self.create_from_json_url url
      begin
        json_str = open(url).read
        File.open(File.join(__dir__, '..', 'tmp', 'setting.json'), 'w') do |f|
          f.print json_str
        end
      rescue => e
        begin
          json_str = open(File.join(__dir__, '..', 'tmp', 'setting.json')).read
        rescue => e
          return self.new
        end
      end
      hash = JSON.parse json_str
      new hash.keys.map(&:to_sym).zip(hash.values).to_h
    end
  end
end
