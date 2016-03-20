
# vim:ts=2:sw=2

#$: << 'lib/cangallo'
require 'spec_helper'

require 'qcow2'
require 'fileutils'

describe Cangallo::Qcow2 do
  before :all do
    @tmpdir = Dir.mktmpdir('qcow2')
  end

  after :all do
    FileUtils.rm_rf(@tmpdir)
  end

  context "creating the base image" do
    before :all do
      @path = File.join(@tmpdir, 'base.qcow2')
      Cangallo::Qcow2.create(@path, nil, 100*1024*1024) # 100 Mb
    end

    it "should be able to create it" do
      expect(File).to exist(@path)
    end

    it 'should get proper info' do
      qcow2 = Cangallo::Qcow2.new(@path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(100*1024*1024)
      expect(info['cluster-size']).to eq(65536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200704)
    end

    if ENV['TRAVIS'] != 'true'
      it 'should be able to compute sha1' do
        qcow2 = Cangallo::Qcow2.new(@path)

        sha1 = qcow2.sha1
        expect(sha1).to eq("2c2ceccb5ec5574f791d45b63c940cff20550f9a")
      end
    end
  end

  context "with the child image" do
    before :all do
      @path = File.join(@tmpdir, 'child.qcow2')
      # 200 Mb
      Cangallo::Qcow2.create(@path, File.join(@tmpdir, 'base.qcow2'), 200*1024*1024)
    end

    it "should be able to create it" do
      expect(File).to exist(@path)
    end

    it 'should get proper info' do
      qcow2 = Cangallo::Qcow2.new(@path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(200*1024*1024)
      expect(info['cluster-size']).to eq(65536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200704)
      expect(File.basename(info['backing-filename'])).to eq('base.qcow2')
    end

    if ENV['TRAVIS'] != 'true'
      it 'should be able to compute sha1' do
        qcow2 = Cangallo::Qcow2.new(@path)

        sha1 = qcow2.sha1
        expect(sha1).to eq("fd7c5327c68fcf94b62dc9f58fc1cdb3c8c01258")
      end
    end
  end
end

