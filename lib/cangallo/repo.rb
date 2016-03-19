
require "yaml"
require "open-uri"

# vim:ts=2:sw=2

module Cangallo

  class Repo
    attr_reader :images, :tags, :path, :name

    VERSION = 0

    def initialize(conf)
      @conf = conf
      @path = File.expand_path(@conf["path"])
      @name = @conf["name"]

      read_index
    end

    def index_data(images = {}, tags = {}, version = VERSION)
      {
        "version" => version,
        "images"  => images,
        "tags"    => tags
      }
    end

    def index_path
      metadata_path("index")
    end

    def read_index(index = nil)
      if !index
        if File.exist?(index_path)
          data = YAML.load(File.read(index_path))
        else
          data = index_data()
        end
      else
        data = YAML.load(index)
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
      data["sha256"] = name
      @images[name] = data
    end

    def add_image(file, data = {})
      parent_sha256 = nil
      parent = nil
      parent_path = nil

      if data["parent"]
        parent_sha256 = data["parent"]
        parent = self.images[parent_sha256]

        if !parent
          raise "Parent not found"
        end

        parent_path = File.expand_path(self.image_path(parent_sha256))
      end

      puts "Calculating image sha256 with libguestfs (it will take some time)"
      qcow2 = Cangallo::Qcow2.new(file)
      sha256 = qcow2.sha256
      sha256.strip! if sha256

      puts "Image SHA256: #{sha256}"

      puts "Copying file to repository"
      image_path = self.image_path(sha256)
      qcow2.copy(image_path, :parent => parent_path)

      qcow2 = Cangallo::Qcow2.new(image_path)
      info = qcow2.info

      info_data = info.select do |k,v|
        %w{virtual-size format actual-size format-specific}.include?(k)
      end

      data.merge!(info_data)

      data["file-sha256"] = Digest::SHA256.file(file).hexdigest

      if parent
        qcow2.rebase("#{parent_sha256}.qcow2")
        data["parent"] = parent_sha256
      end

      self.add(sha256, data)
      self.write_index

      sha256
    end

    def add_tag(tag, image)
        img = find(image)
        @tags[tag] = img
        write_index
    end

    def find(name)
      length = name.length
      found = @images.select do |sha256, data|
        sha256[0, length] == name
      end

      if found && found.length > 0
        return found.first.first
      end

      found = @tags.select do |tag, sha256|
        tag == name
      end

      if found && found.length > 0
        return found.first[1]
      end

      nil
    end

    def get(name)
      image = find(name)

      return nil if !image

      @images[image]
    end

    def ancestors(name)
      ancestors = []

      image = get(name)
      ancestors << image["sha256"]

      while image["parent"]
        image = image["parent"]
        ancestors << image["sha256"]
      end

      ancestors
    end

    def url
      @conf["url"]
    end

    def fetch
      return nil if @conf["type"] != "remote"

      uri = URI.join(url, "index.yaml")

      open(uri, "r") do |f|
        data = f.read
        read_index(data)
      end

      write_index
    end

    def sign
      Keybase.sign(index_path)
    end

    def verify
      Keybase.verify(index_path)
    end
  end

end

