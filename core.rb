require 'mailparser'
require 'null_logger'
require_relative 'config'

module DecoMailFilter
  DUMMY_MAIL_TO = 'bcc@deco-project.org'

  class Core
    def initialize config = Config.new
      @bcc_conversion = config.bcc_conversion
      @encrypt_attachments = config.encrypt_attachments
    end

    attr_accessor :logger

    def logger
      @logger ||= NullLogger.new
    end

    def work input
      mail = MailParser::Message.new(input)

      logger.info("From: #{mail.from}")

      # To: の数確認
      flag_to = false
      flag_to = true if mail.to.size > 1
      logger.info("To size: #{mail.to.size}")

      # Cc: の存在確認
      flag_cc = false
      flag_cc = true if mail.cc.size >= 1
      logger.info("Cc size: #{mail.cc.size}")

      # BCC変換が無効の場合
      # 宛先ドメインが全て同じであることの確認
      if !@bcc_conversion && (mail.to.map(&:domain) + mail.cc.map(&:domain)).uniq.size == 1
        flag_to = false
        flag_cc = false
      end

      # mail出力
      output = ''

      # header
      mail.header.add('x-mail-filter', "DECO Mail Filter\r\n")
      mail.header.keys.each do | key |
        if key == 'to' && (flag_to || flag_cc)
          output += "#{key}: #{DUMMY_MAIL_TO}\r\n"
          logger.info("fix To: #{DUMMY_MAIL_TO}")
        elsif key == 'cc'
          # drop
          logger.info("remove Cc")
        else
          if mail.header.raw(key).kind_of?(Array)
            mail.header.raw(key).each do | item |
              output += "#{key}: #{item.to_s}"
            end
          else
            output += "#{key}: #{mail.header.raw(key).to_s}"
          end
        end
      end
      # body
      output += mail.rawbody
      logger.info("end")
      output
    end
  end
end
