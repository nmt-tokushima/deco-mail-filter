require 'mailparser'
require 'syslog'
include Syslog::Constants
require 'logger'

Syslog.open("DECO_MF", LOG_PID|LOG_NDELAY, LOG_MAIL) unless Syslog.opened?
Syslog.info("start")
Syslog.info("RCPT TO: [#{ARGV[0].chop}]")

class DecoMailFilter
  DUMMY_MAIL_TO = 'bcc@deco-project.org'

  def initialize bcc_conversion = true
    @bcc_conversion = bcc_conversion
  end

  def work input
    mail = MailParser::Message.new(input)

    Syslog.info("From: #{mail.from}")

    # To: の数確認
    flag_to = false
    flag_to = true if mail.to.size > 1
    Syslog.info("To size: #{mail.to.size}")

    # Cc: の存在確認
    flag_cc = false
    flag_cc = true if mail.cc.size >= 1
    Syslog.info("Cc size: #{mail.cc.size}")

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
        Syslog.info("fix To: #{DUMMY_MAIL_TO}")
      elsif key == 'cc'
        # drop
        Syslog.info("remove Cc")
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
    Syslog.info("end")
    output
  end
end
