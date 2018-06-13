module DecoMailFilter
  class Config
    attr_reader :bcc_conversion, :bcc_conversion_whitelist, :encrypt_attachments

    def initialize bcc_conversion: true, bcc_conversion_whitelist: [], encrypt_attachments: false
      @bcc_conversion = bcc_conversion
      @bcc_conversion_whitelist = bcc_conversion_whitelist
      @encrypt_attachments = encrypt_attachments
    end
  end
end
