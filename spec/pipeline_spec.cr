require "./spec_helper"

describe Bus::Pipeline do
  it "has a default origin if none is given" do
    pipeline = Bus::Pipeline(Int32).new

    pipeline.origin.class.should eq String
    pipeline.origin.should match /\w{8}-\w{4}-\w{4}-\w+/
  end

  it "is a functional channel" do
    pipeline = Bus::Pipeline(Int32).new(3)

    pipeline.send(1337)
    pipeline.receive.should eq 1337
  end
end