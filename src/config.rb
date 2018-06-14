module DecoMailFilter
  class Config
    DEFAULT_DUMMY_TO = 'bcc@deco-project.org'

    attr_reader(
      :bcc_conversion,
      :bcc_dummy_to,
      :bcc_conversion_whitelist,
      :encrypt_attachments
    )

    def initialize(
      bcc_conversion: true,
      bcc_dummy_to: DEFAULT_DUMMY_TO,
      bcc_conversion_whitelist: [],
      encrypt_attachments: false
    )
      @bcc_conversion = bcc_conversion
      @bcc_dummy_to = bcc_dummy_to
      @bcc_conversion_whitelist = bcc_conversion_whitelist
      @encrypt_attachments = encrypt_attachments
    end
  end
end
