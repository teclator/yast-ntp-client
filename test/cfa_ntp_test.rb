require_relative "test_helper"

require "cfa/memory_file"
require "ntp/cfa/ntp"

describe Yast::Ntp::CFA::NtpConf do
  subject { described_class.new(file_handler: file) }

  context "with ip version" do
    let(:file) { CFA::MemoryFile.new("restrict -6 default notrap nomodify nopeer noquery\n") }

    it "can read and write with ip version" do
      subject.load
      subject.save
    end
  end

  context "without ip version" do
    let(:file) { CFA::MemoryFile.new("restrict default notrap nomodify nopeer noquery\n") }

    it "can read and write with ip version" do
      subject.load
      subject.save
    end
  end

  context "more complex file" do
    let(:file) { CFA::MemoryFile.new(File.read(File.expand_path("../data/scr_root_read/etc/ntp.conf", __FILE__)))}

    it "can read and write with ip version" do
      subject.load
      subject.save
    end
  end

end
