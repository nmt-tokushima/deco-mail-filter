require 'zip'
require 'fileutils'

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
end
