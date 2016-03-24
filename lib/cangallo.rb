
# vim:ts=2:sw=2

require 'cangallo/qcow2'
require 'cangallo/config'
require 'cangallo/repo'
require 'cangallo/cangafile'
require 'cangallo/libguestfs'
require 'cangallo/keybase'

class Cangallo
  def initialize
    @config = Cangallo::Config.new
  end

  def repo(name = nil)
    @config.repo(name)
  end

  def get_images
    info = []

    @config.repos.each do |r|
      repo = self.repo(r)

      repo.images.each do |sha256, image|
        name = repo.short_name(sha256)

        info << {
          "repo"    => r,
          "sha256"  => sha256,
          "name"    => "#{r}:#{name}",
          "size"    => image["actual-size"],
          "parent"  => short_name(image["parent"], r),
          "description" => image["description"]
        }
      end
    end

    info
  end

  def parse_name(name)
    slices = name.split(':')

    repo = nil
    name = name

    if slices.length > 1
      repo = slices[0]
      name = slices[1]
    end

    return repo, name
  end

  def short_name(string, repo = nil)
    return nil if !string

    img_repo, img_name = parse_name(string)
    img_repo ||= repo

    image = self.repo(img_repo).find(img_name)
    name = self.repo(img_repo).short_name(image)

    "#{img_repo}:#{name}"
  end

  def find(string)
    repo, name = parse_name(string)
    return "#{repo}:#{self.repo(repo).find(name)}" if repo

    image = self.repo.find(name)
    return "#{self.repo.name}:#{image}" if image

    @config.repos.each do |r|
      image = self.repo(r).find(name)
      return "#{r}:#{image}" if image
    end

    nil
  end

  def get(string)
    image = find(string)
    repo, name = parse_name(name)

    self.repo(repo).get(name)
  end
end

