
# vim:tabstop=2:sw=2:et:

require 'json'
require 'systemu'
require 'tempfile'
require 'fileutils'
require 'yaml'

class Cangallo

  class Cangafile
    attr_accessor :data

    ACTIONS = {
      "copy" => lambda do |input|
        required = %w{source destination}
        if (required & input.keys) != required
          raise %s{copy command needs "source" and "destination"}
        end

        "copy-in #{input["source"}:#{input["destination"]}"
      end,

      "run" => lambda do |input|
        if input.class != String
          raise %s{run command needs a string}
        end

        "run-command #{input}"
      end
    }

    def initialize(file)
      text = File.read(file)
      @data = YAML.load(text)

      if !@data["tasks"] || @data["tasks"].class != Array
        raise "No tasks defined or it's not an array"
      end

      @tasks = @data["tasks"]
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
      @tasks.each do |task|
        if task.class != Hash
          raise "This task is not a hash: #{task}"
        end


      end
    end

    def libguestfs_commands_old
      text = file_commands
      text << run_commands
      text
    end

    def parent
      @data["parent"]
    end
  end

end
