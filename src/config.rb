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
      :bcc_conversion_whitelist,
      :bcc_conversion_disable_domains,
      :encrypt_attachments, # TODO: Replace to "attachments_encryption"
      :attachments_encryption_password_length,
      :attachments_encryption_subtitle,
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
      bcc_conversion_whitelist: [],
      encrypt_attachments: false, # TODO: Replace to "attachments_encryption"
      attachments_encryption_password_length: 8,
      attachments_encryption_subtitle: '',
      attachments_encryption_additional_text: '',
      attachments_encryption_encoding: ENCODING_BASE64,
      attachments_encryption_password_notification: false,
      attachments_encryption_disable_emails: [],
      attachments_encryption_disable_domain_froms: [],
      attachments_encryption_disable_domain_tos: []
    )
      @bcc_conversion = bcc_conversion
      @bcc_dummy_to = bcc_dummy_to
      @bcc_conversion_whitelist = bcc_conversion_whitelist
      @encrypt_attachments = encrypt_attachments
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

      # NOTE: Temporary code for compatibility
      value = hash.delete "attachments_encryption"
      unless value.nil?
        hash["encrypt_attachments"] = value
      end
      value = hash.delete "bcc_conversion_disable_domains"
      unless value.nil?
        hash["bcc_conversion_whitelist"] = value
      end

      new hash.keys.map(&:to_sym).zip(hash.values).to_h
    end
  end
end
