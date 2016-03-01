
require "yaml"

# vim:ts=2:sw=2

module Cangallo

  class Repo
    attr_reader :images, :tags

    VERSION = 0

    def initialize(path)
      @path = path

      read_index
    end

    def index_data(images = {}, tags = {}, version = VERSION)
      {
        "version" => version,
        "images"  => images,
        "tags"    => tags
      }
    end

    def read_index
      index_path = metadata_path("index")

      if File.exist?(index_path)
        data = YAML.load(File.read(index_path))
      else
        data = index_data()
      end

      @images = data["images"]
      @tags   = data["tags"]
    end

    def write_index
      data = index_data(@images, @tags)

      open(metadata_path("index"), "w") do |f|
        f.write(data.to_yaml)
      end
    end

    def metadata_path(name)
      File.join(@path, "#{name}.yaml")
    end

    def image_path(name)
      File.join(@path, "#{name}.qcow2")
    end

    def add(name, data)
      data["creation-time"] = Time.now
      @images[name] = data
    end

    def add_image(file, data = {})
      parent_sha1 = nil
      parent = nil
      parent_path = nil

      if data["parent"]
        parent_sha1 = data["parent"]
        parent = self.images[parent_sha1]

        if !parent
          STDERR.puts "Parent not found"
          exit(-1)
        end

        parent_path = File.expand_path(self.image_path(parent_sha1))
      end

      puts "Calculating image sha1 with libguestfs (it will take some time)"
      qcow2 = Cangallo::Qcow2.new(file)
      sha1 = qcow2.sha1
      sha1.strip! if sha1

      puts "Image SHA1: #{sha1}"

      puts "Copying file to repository"
      image_path = self.image_path(sha1)
      qcow2.copy(image_path, :parent => parent_path)

      qcow2 = Cangallo::Qcow2.new(image_path)
      info = qcow2.info

      info_data = info.select do |k,v|
        %w{virtual-size format actual-size format-specific}.include?(k)
      end

      data.merge!(info_data)

      data["file-sha1"] = Digest::SHA1.file(file).hexdigest

      if parent
        qcow2.rebase("#{parent_sha1}.qcow2")
        data["parent"] = parent_sha1
      end

      self.add(sha1, data)
      self.write_index
    end

  end

end

