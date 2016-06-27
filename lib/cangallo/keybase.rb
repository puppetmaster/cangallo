
# vim:tabstop=2:sw=2:et:

# Copyright 2016, Javier Fontán Muiños <jfontan@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Cangallo

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


