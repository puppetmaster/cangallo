
# vim:tabstop=2:sw=2:et:

require 'json'
require 'systemu'
require 'tempfile'
require 'fileutils'

class Cangallo

  class LibGuestfs
    def self.virt_customize(image, commands)
      cmd_file = Tempfile.new("canga")

      cmd_file.puts(commands)
      cmd_file.close

      #rc = system("virt-customize -v -x -a #{image} --commands-from-file #{cmd_file.path}")
      rc = system("virt-customize -a #{image} --commands-from-file #{cmd_file.path}")
      cmd_file.unlink

      return rc
    end

    def self.virt_sparsify(image)
      rc = system("virt-sparsify --in-place #{image}")

      return rc
    end
  end
end
