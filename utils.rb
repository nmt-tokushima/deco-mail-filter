require 'tmpdir'
require 'zip'
require 'fileutils'

class DecoMailFilter::Utils
  def self.zipfile_encrypted? zippath
    tmpdir = Dir.mktmpdir
    Zip::InputStream.open zippath, 0 do |input|
      while entry = input.get_next_entry
        save_path = File.join tmpdir, entry.name
        File.open save_path, 'wb' do |f|
          f.puts input.read # Raise Zlib::DataError if this is encrypted
        end
      end
    end
    false
  rescue Zlib::DataError => e
    true
  ensure
    FileUtils.rm_rf tmpdir
  end
end
