require "./spec_helper"

describe Bus::Message do
  pipeline = Bus::Pipeline(Bus::Message).new(capacity: 10)

  it "creates a message with just defaults" do
    msg = Bus::Message.new(
      pipeline: pipeline
    )
    msg.pipeline.should eq pipeline
    msg.body.should eq [""]
    msg.tags.should eq Array(String).new
    msg.parameters.should eq Hash(String, String).new
    msg.uuid.class.should eq CSUUID
  end

  it "creates a message with a string body" do
    msg = Bus::Message.new(
      pipeline: pipeline,
      body: "This is a message body."
    )
    msg.body.should eq ["This is a message body."]
  end

  it "creates a message with an array body" do
    msg = Bus::Message.new(
      pipeline: pipeline,
      body: ["This is the first line", "This is the second line"]
       )

    msg.body[0].should eq "This is the first line"
    msg.body[1].should eq "This is the second line"
  end

  it "Creates a message with everything specified" do
    uuid = CSUUID.new
    origin = CSUUID.new.to_s

    msg = Bus::Message.new(
      pipeline: pipeline,
      body: "This is a message body.",
      tags: ["handler", "handler:test"],
      parameters: {"this" => "that", "that" => "thensome"},
      origin: origin,
      uuid: uuid
    )

    msg.pipeline.should eq pipeline
    msg.body.should eq ["This is a message body."]
    msg.tags.should eq ["handler", "handler:test"]
    msg.parameters.should eq ({"this" => "that", "that" => "thensome"})
    msg.origin.should eq origin
    msg.uuid.should eq uuid
  end

  it "send_evaluation should send a relevant evaluation message" do
    receiver = CSUUID.new.to_s
    first_message = Bus::Message.new(pipeline: pipeline, body: "first message")
    first_message.send_evaluation(
      receiver: receiver
    )
    reply = pipeline.receive

    reply.body.should eq [""]
    reply.tags.should eq ["evaluate()"]
    reply.parameters["relevance"].should eq "0"
    reply.parameters["certainty"].should eq "0"
    reply.parameters["receiver"].should eq receiver
    reply.parameters["uuid"].should eq first_message.uuid.to_s
    reply.origin.should eq first_message.origin
  end

  it "reply should send a reply" do
    receiver = CSUUID.new.to_s
    first_message = Bus::Message.new(pipeline: pipeline, body: "first message")
    first_message.reply(
      body: "second message"
    )
    reply = pipeline.receive

    reply.body.should eq ["second message"]
    reply.origin.should eq first_message.origin
  end
end