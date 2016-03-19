
# vim:tabstop=2:sw=2:et:

require 'json'
require 'systemu'
require 'tempfile'
require 'fileutils'
require 'yaml'

class Cangallo

  class Cangafile
    attr_accessor :data

    def initialize(file)
      text = File.read(file)
      @data = YAML.load(text)
    end

    def file_commands
      text = ""

      if @data["files"]
        @data["files"].each do |line|
          l = line.gsub(" ", ":")
          text << "copy-in #{l}\n"
        end
      end

      return text
    end

    def run_commands
      text = ""

      if @data["run"]
        @data["run"].each do |line|
          text << "run-command #{line}\n"
        end
      end

      return text
    end

    def libguestfs_commands
      text = file_commands
      text << run_commands
      text
    end

    def parent
      @data["parent"]
    end
  end

end
