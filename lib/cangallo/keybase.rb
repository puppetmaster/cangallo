
# vim:tabstop=2:sw=2:et:

module Cangallo

  module Keybase
    def self.sign(file)
      sig_file = "#{file}.sig"
      cmd = "keybase pgp sign --detached --infile '#{file}' " \
                                        "--outfile '#{sig_file}'"
      rc = system(cmd)
      raise "Error executing keybase sign command" if !rc
    end

    def self.verify(file)
      sig_file = "#{file}.sig"
      cmd = "keybase pgp verify --detached '#{sig_file}' " \
                               "--infile '#{file}'"
      rc = system(cmd)
      raise "Error executing keybase verify command" if !rc
    end
  end
end


