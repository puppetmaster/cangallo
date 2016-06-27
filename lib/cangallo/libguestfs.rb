
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

require 'json'
require 'systemu'
require 'tempfile'
require 'fileutils'

class Cangallo

  class LibGuestfs
    def self.virt_customize(image, commands, params = "")
      cmd_file = Tempfile.new("canga")

      cmd_file.puts(commands)
      cmd_file.close

      #rc = system("virt-customize -v -x -a #{image} --commands-from-file #{cmd_file.path}")
      rc = system("virt-customize -a #{image} #{params.join(" ")} " <<
                  "--commands-from-file #{cmd_file.path}")
      cmd_file.unlink

      return rc
    end

    def self.virt_sparsify(image)
      rc = system("virt-sparsify --in-place #{image}")

      return rc
    end
  end
end
