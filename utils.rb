require 'zip'
require 'find'

class DecoMailFilter::Utils
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
    zippath
  end
end
