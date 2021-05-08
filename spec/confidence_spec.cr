require "./spec_helper"

describe Bus::Confidence do
  it "a confidence object can be instantiated and interrogated" do
    confidence = Bus::Confidence.new
    confidence.relevance.should eq 0
    confidence.certainty.should eq 0
    confidence.force.should be_nil

    confidence = Bus::Confidence.new(relevance: 2, certainty: 1000000)
    confidence.relevance.should eq 2
    confidence.certainty.should eq 1000000
    confidence.force.should be_nil

    confidence = Bus::Confidence.new(relevance: 0, certainty: 0, force: true)
    confidence.relevance.should eq 0
    confidence.certainty.should eq 0
    confidence.force.should be_true

    confidence = Bus::Confidence.new(force: true)
    confidence.relevance.should eq 0
    confidence.certainty.should eq 0
    confidence.force.should be_true

    confidence = Bus::Confidence.new(false)
    confidence.relevance.should eq 0
    confidence.certainty.should eq 0
    confidence.force.should be_false
  end

  it "confidence objects can be sorted" do
    ary = [] of Bus::Confidence

    ary << Bus::Confidence.new
    ary << Bus::Confidence.new(relevance: -2, certainty: -1000000, force: true)
    ary << Bus::Confidence.new(relevance: 2, certainty: 500000)
    ary << Bus::Confidence.new(relevance: 2, certainty: 1000000)
    ary << Bus::Confidence.new(relevance: 1, certainty: 1000000)

    sorted_ary = ary.sort.reverse

    sorted_ary[0].relevance.should eq 2
    sorted_ary[0].certainty.should eq 1000000
    sorted_ary[0].relevance.should eq sorted_ary[1].relevance
    sorted_ary[2].relevance.should eq 1
    sorted_ary[2].certainty.should eq 1000000
    sorted_ary[4].certainty.should eq -1000000
    sorted_ary[4].force.should be_true
  end
end
