require 'mailparser'
require 'null_logger'
require 'kconv'
require 'base64'
require 'mail'
require_relative 'config'
require_relative 'utils'

module DecoMailFilter
  ENCRYPTED_ATTACHMENT_FILENAME = 'attachments.zip'
  # TODO: ファイル名を日本語に(SJIS?)

  class UnsupportedEncodingMechanism < StandardError; end

  class Core
    def initialize config: Config.new
      @bcc_conversion = config.bcc_conversion
      @bcc_dummy_to = config.bcc_dummy_to
      @bcc_conversion_disable_domains = config.bcc_conversion_disable_domains
      @attachments_encryption = config.attachments_encryption
      @attachments_encryption_password_length = config.attachments_encryption_password_length
      @attachments_encryption_subject = config.attachments_encryption_subject
      @attachments_encryption_additional_text = config.attachments_encryption_additional_text
      @attachments_encryption_password_notification = config.attachments_encryption_password_notification
      @smtp_host = config.smtp_host
      @smtp_port = config.smtp_port
    end

    attr_accessor :logger

    def logger
      @logger ||= NullLogger.new
    end

    def main_text_parts mail
      if mail.multipart?
        content_type = mail.header['content-type'].first
        if content_type.type == 'multipart' && content_type.subtype == 'alternative'
          [mail.body]
        else
          mail.part.select do |e|
            e.header['content-disposition'].nil? || e.header['content-disposition'].first.type != 'attachment'
          end
        end
      else
        [mail.body]
      end
    end

    def main_text_part mail
      main_text_parts(mail).first
    end

    def attachment_parts mail
      mail.part.select do |e|
        e.header['content-disposition']&.first&.type == 'attachment'
      end
    end

    def have_attachment? mail
      !attachment_parts(mail).empty?
    end

    def write_attachments mail, dir
      attachment_parts(mail).each do |e|
        filename = e.filename.tosjis
        case e.header['content-type'].first.type
        when 'text'
          File.open(File.join(dir, filename), 'w') do |f|
            f.write e.body
          end
        else
          mechanism = e.header['content-transfer-encoding'].first.mechanism
          case mechanism
          when 'base64'
            File.open(File.join(dir, filename), 'wb') do |f|
              f.write Base64.decode64 e.rawbody
            end
          when 'quoted-printable'
            File.open(File.join(dir, filename), 'wb') do |f|
              f.write e.rawbody.unpack1 'M'
            end
          else
            raise UnsupportedEncodingMechanism.new mechanism
          end
        end
      end
    end

    def attachment_filenames mail
      attachment_parts(mail).map { |e| e.filename.tosjis }
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
            if @bcc_conversion_disable_domains.include? domains.first
              flag_to = false
              flag_cc = false
            end
          end
        end
      end

      flag_attachments_encryption = @attachments_encryption && have_attachment?(mail)

      # mail出力
      header = ''
      body = ''

      # Encrypt attachments
      new_mail = nil
      if flag_attachments_encryption
        logger.info("encrypt attachments executing")
        tmp_attachments = Dir.mktmpdir
        begin
          write_attachments mail, tmp_attachments
        rescue UnsupportedEncodingMechanism => e
          FileUtils.rm_rf tmp_attachments
          send_unsupported_encoding_mechanism_mail mail.from
          raise e
        end
        tmp_zip_dir = Dir.mktmpdir
        zippath = File.join tmp_zip_dir, 'attachments.zip'
        password = Utils.generate_password length: @attachments_encryption_password_length
        Utils.make_zip_file tmp_attachments, zippath, password

        original_subject = mail.subject != nil ? mail.subject : 'n/a'
        original_date = mail.header['Date'] != nil ? mail.header['Date'].to_s : 'n/a'
        send_attachments_encryption_password_mail(
          mail.from,
          original_subject, original_date,
          attachment_filenames(mail), password
        )

        logger.info("password: #{password.gsub('%', '%%')}") # TODO: Remove later
        # NOTE: % -> %% for avoiding "malformed format string" error
        # ref. https://stackoverflow.com/questions/13432122/string-interpolation-with-actual-in-string
        new_mail = Mail.new
        if main_text_part(mail).multipart?
          body_part = Mail::Part.new
          text_part = main_text_part(mail).part.find { |e| e.header['content-type'].first.type == 'text' && e.header['content-type'].first.subtype == 'plain' }
          charset = text_part.header['content-type'].first.params['charset']
          text_part_body =
            if charset == 'iso-2022-jp' || charset == 'ISO-2022-JP'
              text_part.body.force_encoding(Encoding::ASCII_8BIT)
            else
              text_part.body
            end
          body_part.text_part = Mail::Part.new do
            body text_part_body
            content_type text_part.header['content-type'].first.raw
            content_transfer_encoding text_part.header['content-transfer-encoding'].first.mechanism
          end
          html_part = main_text_part(mail).part.find { |e| e.header['content-type'].first.type == 'text' && e.header['content-type'].first.subtype == 'html' }
          charset = html_part.header['content-type'].first.params['charset']
          html_part_body =
            if charset == 'iso-2022-jp' || charset == 'ISO-2022-JP'
              html_part.body.force_encoding(Encoding::ASCII_8BIT)
            else
              html_part.body
            end
          body_part.html_part = Mail::Part.new do
            body html_part_body
            content_type html_part.header['content-type'].first.raw
            content_transfer_encoding html_part.header['content-transfer-encoding'].first.mechanism
          end
          new_mail.add_part body_part
        else
          rawbody = main_text_part(mail).rawbody
          body_part = Mail::Part.new do
            body rawbody
            content_type mail.part.first.header['content-type'].first.raw
            content_transfer_encoding mail.part.first.header['content-transfer-encoding'].first.mechanism
          end
          new_mail.add_part body_part
        end
        new_mail.add_file filename: ENCRYPTED_ATTACHMENT_FILENAME, content: File.binread(zippath)
        FileUtils.rm_rf tmp_attachments
        FileUtils.rm_rf tmp_zip_dir
        logger.info("encrypt attachments success")
      end

      # header
      mail.header.add('x-mail-filter', "DECO Mail Filter\r\n")
      if flag_attachments_encryption
        mail.header.add('X-DECO-Mail-Filter-Attachments-Encryption', "done\r\n")
      end
      mail.header.keys.each do | key |
        if key == 'to' && (flag_to || flag_cc)
          header += "#{key}: #{@bcc_dummy_to}\r\n"
          logger.info("fix To: #{@bcc_dummy_to}")
        elsif key == 'cc' && flag_cc
          # drop
          logger.info("remove Cc")
        elsif key == 'content-type' && flag_attachments_encryption
          # boundaryを古いメールのものから新しいメールのものに差し替えのため
          header += "#{key}: #{new_mail.header['content-type']}\r\n"
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
      end
      logger.info("end")
      header + body
    end

    private
      def send_attachments_encryption_password_mail(
        sender,
        subject, date,
        attachment_filenames, password
      )
        return # NOTE: Temporarily disable this method
        # TODO: Remove "return"
        send_pass_mail(
          sender, sender,
          subject, date,
          attachment_filenames, password
        )
        if @attachments_encryption_password_notification
          @rcpts.each do |r|
            send_pass_mail(
              sender, r,
              subject, date,
              attachment_filenames, password
            )
          end
        end
      end

      def send_pass_mail(
        sender, rcpt,
        original_subject, original_date,
        attachment_filenames, password
      )
        mail = Mail.new
        mail.from = sender
        mail.to = rcpt
        if @attachments_encryption_subject == ''
          mail.subject = "【DECO Mail Filter】添付ファイル自動暗号化通知"
        else
          mail.subject = @attachments_encryption_subject
        end
        mail.body = <<~EOS
以下のメールの添付ファイルを暗号化して送信しました。

---
Date: #{original_date}
From: #{sender}
To: #{rcpt}
Subject: #{original_subject}
添付ファイル名: #{attachment_filenames.join ', '}
---

暗号化添付ファイル名: #{ENCRYPTED_ATTACHMENT_FILENAME}
展開パスワード: #{password}

        #{@attachments_encryption_additional_text}
        EOS
        mail.delivery_method(:smtp, address: @smtp_host, port: @smtp_port)
        mail.deliver
      end

      def send_unsupported_encoding_mechanism_mail sender
        mail = Mail.new
        mail.from = sender # TODO: senderで良い？設定に追加する？固定値利用？
        mail.to sender
        mail.subject '【DECO Mail Filter】添付ファイル自動暗号化エラー'
        mail.body '対応していない添付ファイルのエンコード形式です。添付ファイルはBase64かQuoted-Printable形式でエンコードしてください。'
        mail.delivery_method(:smtp, address: @smtp_host, port: @smtp_port)
        mail.deliver
      end
  end
end
