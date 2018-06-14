require 'mailparser'
require 'null_logger'
require 'nkf'
require 'base64'
require 'mail'
require_relative 'config'

module DecoMailFilter
  class Core
    attr_reader :work_side_effect

    def initialize config: Config.new
      @bcc_conversion = config.bcc_conversion
      @bcc_dummy_to = config.bcc_dummy_to
      @bcc_conversion_whitelist = config.bcc_conversion_whitelist
      @encrypt_attachments = config.encrypt_attachments
      @work_side_effect = nil
    end

    attr_accessor :logger

    def logger
      @logger ||= NullLogger.new
    end

    def have_attachment? mail
      if mail.multipart?
        if mail.header['content-type'].first.tap { |e| break e.type, e.subtype } == ['multipart', 'mixed']
          true
        else
          false
        end
      else
        false
      end
    end

    def write_attachments mail, dir
      return unless have_attachment? mail
      mail.part[1..-1].each do |e|
        filename = NKF.nkf '-w', e.filename
        File.open(File.join(dir, filename), 'wb') do |f|
          f.write Base64.decode64 e.rawbody
        end
      end
    end

    def work input
      mail = MailParser::Message.new(input)

      logger.info("From: #{mail.from}")

      flag_to = false
      flag_cc = false
      logger.info("BCC conversion: #{@bcc_conversion}")
      if @bcc_conversion
        # To: の数確認
        flag_to = true if mail.to.size > 1
        logger.info("To size: #{mail.to.size}")

        # Cc: の存在確認
        flag_cc = true if mail.cc.size >= 1
        logger.info("Cc size: #{mail.cc.size}")

        # BCC変換を無効にする特例判定
        if flag_to || flag_cc
          domains = (mail.to.map(&:domain) + mail.cc.map(&:domain))
          # 宛先ドメインが全て同じであることの確認
          if domains.uniq.size == 1
            # 指定されたドメインであることの確認
            if @bcc_conversion_whitelist.include? domains.first
              flag_to = false
              flag_cc = false
            end
          end
        end
      end

      flag_encrypt_attachments = @encrypt_attachments && have_attachment?(mail)

      # mail出力
      header = ''
      body = ''

      # Encrypt attachments
      new_mail = nil
      if flag_encrypt_attachments
        tmp_attachments = Dir.mktmpdir
        write_attachments mail, tmp_attachments
        tmp_zip_dir = Dir.mktmpdir
        zippath = File.join tmp_zip_dir, 'attachments.zip'
        password = Utils.generate_password
        Utils.make_zip_file tmp_attachments, zippath, password
        work_side_effect_merge({ encrypt_attachments: true, password: password })
        new_mail = Mail.new
        # TODO: partの0番目に multipart/alternative があることが前提になっているので修正(※修正の必要が本当にあるかどうかも考える)
        if mail.part.first.multipart?
          body_part = Mail::Part.new
          text_part = mail.part.first.part.find { |e| e.header['content-type'].first.type == 'text' && e.header['content-type'].first.subtype == 'plain' }
          body_part.text_part = Mail::Part.new do
            body text_part.body
            content_type text_part.header['content-type'].first.raw
            content_transfer_encoding text_part.header['content-transfer-encoding'].first.mechanism
          end
          html_part = mail.part.first.part.find { |e| e.header['content-type'].first.type == 'text' && e.header['content-type'].first.subtype == 'html' }
          body_part.html_part = Mail::Part.new do
            body html_part.body
            content_type html_part.header['content-type'].first.raw
            content_transfer_encoding html_part.header['content-transfer-encoding'].first.mechanism
          end
          new_mail.add_part body_part
        else
          new_mail.body = mail.part.first.rawbody
        end
        new_mail.add_file filename: 'attachments.zip', content: File.binread(zippath)
        # TODO: ファイル名を日本語に(SJIS?)
        FileUtils.rm_rf tmp_attachments
        FileUtils.rm_rf tmp_zip_dir
      end

      # header
      mail.header.add('x-mail-filter', "DECO Mail Filter\r\n")
      if flag_encrypt_attachments
        mail.header.add('X-DECO-Mail-Filter-Attachments-Encryption', "done\r\n")
      end
      mail.header.keys.each do | key |
        if key == 'to' && (flag_to || flag_cc)
          header += "#{key}: #{@bcc_dummy_to}\r\n"
          logger.info("fix To: #{@bcc_dummy_to}")
        elsif key == 'cc' && flag_cc
          # drop
          logger.info("remove Cc")
        elsif key == 'content-type' && flag_encrypt_attachments
          # boundaryを古いメールのものから新しいメールのものに差し替えのため
          header += "#{key}: #{new_mail.header['content-type']}"
        else
          if mail.header.raw(key).kind_of?(Array)
            mail.header.raw(key).each do | item |
              header += "#{key}: #{item.to_s}"
            end
          else
            header += "#{key}: #{mail.header.raw(key).to_s}"
          end
        end
      end
      # body
      if new_mail.nil?
        body += mail.rawbody
      else
        body += new_mail.to_s.split("\r\n\r\n")[1..-1].join("\r\n\r\n")
        # TODO: partの0番目に multipart/alternative があることが前提になっているので修正(※修正の必要が本当にあるかどうかも考える)
      end
      logger.info("end")
      header + body
    end

    private
      def work_side_effect_merge(hash)
        @work_side_effect = (@work_side_effect || {}).merge(hash)
      end
  end
end
