
# vim:ts=2:sw=2

#$: << 'lib/cangallo'
require 'spec_helper'

require 'qcow2'
require 'fileutils'

include Cangallo

describe Qcow2 do
  before :all do
    @tmpdir = Dir.mktmpdir('qcow2')
  end

  after :all do
    FileUtils.rm_rf(@tmpdir)
  end

  context "creating the base image" do
    before :all do
      @path = File.join(@tmpdir, 'base.qcow2')
      Qcow2.create(@path, nil, 10737418240) # 10Gb
    end

    it "should be able to create it" do
      expect(File).to exist(@path)
    end

    it 'should get proper info' do
      qcow2 = Qcow2.new(@path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(10737418240)
      expect(info['cluster-size']).to eq(65536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200704)
    end
  end

  context "with the child image" do
    before :all do
      @path = File.join(@tmpdir, 'child.qcow2')
      Qcow2.create(@path, File.join(@tmpdir, 'base.qcow2'), 21474836480) # 20Gb
    end

    it "should be able to create it" do
      expect(File).to exist(@path)
    end

    it 'should get proper info' do
      qcow2 = Qcow2.new(@path)

      info = qcow2.info
      expect(info).not_to eq(nil)

      expect(info['virtual-size']).to eq(21474836480)
      expect(info['cluster-size']).to eq(65536)
      expect(info['format']).to eq('qcow2')
      expect(info['actual-size']).to eq(200704)
      expect(File.basename(info['backing-filename'])).to eq('base.qcow2')
    end
  end
end

