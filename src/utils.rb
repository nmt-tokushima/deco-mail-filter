require 'zip'
require 'find'
require 'passgen'

class DecoMailFilter::Utils
  def self.zipfile_non_encrypted? zippath
    Zip::InputStream.open zippath, 0 do |input|
      while entry = input.get_next_entry
        return false if entry.gp_flags == 9
      end
    end
    true
  end

  def self.zipfile_encrypted? zippath
    Zip::InputStream.open zippath, 0 do |input|
      while entry = input.get_next_entry
        # If at least 1 file which is not encrypted exists,
        # the result of this method should be false. (probabbly...)
        return false if entry.gp_flags == 0
        # NOTE: `entry.gp_flags == 9` means encrypted.
        # TODO: Research that `entry.gp_flags == 9` is the correct condition.
      end
    end
    true
  end

  def self.make_zip_file(filedir, zippath, password)
    encrypter = Zip::TraditionalEncrypter.new(password)
    buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), encrypter) do |out|
      Find.find(filedir) do |p|
        if File::ftype(p) == "file"
          out.put_next_entry(File.basename(p))
          file_buf = File.open(p) { |e| e.read }
          out.write file_buf
        end
      end
    end
    File.open(zippath, 'wb') { |f| f.write(buffer.string) }
  end

  def self.extract_zip_file zippath, filedir, password: nil
    decrypter = password.nil? ? nil : Zip::TraditionalDecrypter.new(password)
    Zip::InputStream.open zippath, 0, decrypter do |input|
      while entry = input.get_next_entry
        save_path = File.join filedir, entry.name
        File.open save_path, 'wb' do |f|
          f.puts input.read
        end
      end
    end
  end

  def self.generate_password
    Passgen::generate symbols: true
  end

  def self.send_pass_mail(
    sender, rcpt, subject, original_subject, original_date,
    attachment_filenames, password, additional_text,
    smtp_host, smtp_port
  )
    mail = Mail.new
    mail.from = sender
    mail.to = rcpt
    mail.subject = subject
    mail.body = <<~EOS
以下のメールの添付ファイルを暗号化して送信しました。

---
Date: #{original_date}
From: #{sender}
To: #{rcpt}
Subject: #{original_subject}
添付ファイル名: #{attachment_filenames.join ', '}
---

暗号化添付ファイル名: #{encrypted_attachment_filename}
展開パスワード: #{password}

    #{additional_text}
    EOS
    mail.delivery_method(:smtp, address: smtp_host, port: smtp_port)
    mail.deliver
  end
end
