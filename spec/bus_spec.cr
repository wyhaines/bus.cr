require "./spec_helper"

describe Bus::VERSION do
  it "has a reasonable version" do
    major, minor, patch = Bus::VERSION
    major =~ /\d/
    minor =~ /\d/
    patch =~ /\d/
  end
end
