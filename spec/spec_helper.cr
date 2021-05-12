require "spec"
require "../src/bus"

class TestHandler < Bus::Handler
  ResultsChannel = Bus::Pipeline(Bus::Message).new(10)

  def handle(msg)
    msg.body << "Handled by #{self}"
    ResultsChannel.send(msg)
  end
end
