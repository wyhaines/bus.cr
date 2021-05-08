require "./spec_helper"

describe Bus do
  it "Bus::VERSION is a string in the expected format" do
    Bus::VERSION.class.should eq String
    Bus::VERSION.split(".").size.should eq 3
  end

  it "Bus::Version works" do
    "#{Bus::Version}" == Bus::VERSION
  end

  it "major level is appropriate" do
    Bus::Version.major =~ /\d+/
  end

  it "minor level is appropriate" do
    Bus::Version.minor =~ /\d+/
  end

  it "patch level is appropriate" do
    Bus::Version.patch =~ /\d+/
  end
end
