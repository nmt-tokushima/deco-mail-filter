module DecoMailFilter
  class Config
    attr_reader :bcc_conversion, :encrypt_attachments

    def initialize bcc_conversion: true, encrypt_attachments: false
      @bcc_conversion = bcc_conversion
      @encrypt_attachments = encrypt_attachments
    end
  end
end
