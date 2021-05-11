require "spec"
require "../src/bus"

class TestHandler < Bus::Handler
  ResultsChannel = Bus::Pipeline(Bus::Message).new(10)

  def initialize(
    @bus : Bus,
    tags : Array(String) = [] of String,
    @force : Bool? = nil
  )
    super(@bus, tags)
  end

  def evaluate(msg)
    ppl = @pipeline

    msg.send_evaluation(receiver: ppl.origin, force: @force) if ppl
  end

  def handle(msg)
    msg.body << "Handled by #{self}"
    ResultsChannel.send(msg)
  end
end
