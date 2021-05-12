require "./spec_helper"

describe Bus::Handler do
  bus = Bus.new
  hand1 = TestHandler.new(bus: bus, tags: ["hand1", "handler", "bm"])
  hand1.listen
  hand2 = TestHandler.new(bus: bus, tags: ["hand2", "handler", "bm"])
  hand2.listen
  hand3 = TestHandler.new(
    bus: bus,
    tags: ["hand3", "handler"],
    force: true)
  hand3.listen
  hand4 = TestHandler.new(
    bus: bus,
    tags: ["hand4", "handler"],
    force: false)
  hand4.listen

  it "can send a message to a single handler" do
    message = bus.message(
      body: "This is a test message.",
      tags: ["hand2"]
    )

    bus.send(message)
    received = TestHandler::ResultsChannel.receive
    received.body.should eq message.body
  end

  it "can send a message to one of several handlers" do
    message = bus.message(
      body: "This is a second test message.",
      tags: ["handler"]
    )

    bus.send(message)
    received = [] of Bus::Message
    received << TestHandler::ResultsChannel.receive
    received[0].body.should eq message.body
  end

  it "can send a message to all of the handlers" do
    message = bus.message(
      body: "This is a second test message.",
      tags: ["handler"],
      strategy: Bus::Message::Strategy::All
    )

    bus.send(message)
    received = [] of Bus::Message
    sleep 0.1
    3.times do
      if TestHandler::ResultsChannel.size == 0
        print "."
        sleep 0.1
        next
      else
        received << TestHandler::ResultsChannel.receive
      end
    end
    received.size.should eq 3
    received[0].body[0].should eq message.body[0]
    TestHandler::ResultsChannel.clear
  end

  it "can send a message to the first top handler" do
    message = bus.message(
      body: "This is a second test message.",
      tags: ["handler"],
      strategy: Bus::Message::Strategy::FirstWinner
    )
    bus.send(message)
    received = [] of Bus::Message
    received << TestHandler::ResultsChannel.receive
    received[0].body.should eq message.body
  end

  it "can send create, send, and receive many messages through multiple handlers to a single winner" do
    start = Time.monotonic
    flag = Channel(Nil).new
    iterations = 10000
    spawn(name: "Benchmark Sender") do
      iterations.times do |count|
        message = bus.message(
          body: "Benchmark message #{count}",
          tags: ["handler"],
          strategy: Bus::Message::Strategy::RandomWinner
        )
        bus.send(message)
      end
    end

    spawn(name: "Benchmark receiver") do
      iterations.times do
        TestHandler::ResultsChannel.receive
      end
      flag.send(nil)
    end

    flag.receive
    finish = Time.monotonic

    puts "\n\nMessages per second (#{iterations} messages -> #{iterations} winners): #{iterations / (finish - start).total_seconds}"
  end

  it "can send create, send, and receive many messages through many handlers" do
    start = Time.monotonic
    flag = Channel(Nil).new
    iterations = 10000
    spawn(name: "Benchmark Sender") do
      iterations.times do |count|
        message = bus.message(
          body: "Benchmark message #{count}",
          tags: ["handler"],
          strategy: Bus::Message::Strategy::All
        )
        bus.send(message)
      end
    end

    spawn(name: "Benchmark receiver") do
      (iterations * 3).times do
        TestHandler::ResultsChannel.receive
      end
      flag.send(nil)
    end

    flag.receive
    finish = Time.monotonic

    puts "\n\nMessages per second (#{iterations} messages -> #{3 * iterations} winners): #{iterations / (finish - start).total_seconds}"
  end
end
