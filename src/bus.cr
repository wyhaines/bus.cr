require "splay_tree_map"
require "uuid"
require "./bus/*"

#####
# A Bus sends messages to interested subscribers. Those subscribers
# can reply to a message. Those replies will be routed back to the
# original sender.
class Bus
  def initialize
    @pending_evaluation = SplayTreeMap(String, Evaluation).new
    @subscriptions = SplayTreeMap(String, Hash(Pipeline(Message), Bool)).new do |h, k|
      h[k] = Hash(Pipeline(Message), Bool).new
    end
    @subscribers = Hash(Pipeline(Message), Array(String)).new
    @pipeline = Pipeline(Message).new(capacity: 20, origin: origin_tag)
    handle_pipeline
    handle_evaluations
  end

  # Generate a random UUID that does not already exist in the subscriptions.
  def origin_tag
    loop do
      id = UUID.random.to_s
      break id if !has_subscription?(id)
    end
  end

  def has_subscription?(key)
    @subscriptions.has_key?(key)
  end

  # The pipeline into the bus exists primarily for message object to have
  # a queue that can be used to submit replies that are intended to go back
  # into the bus. This method creates a fiber that listens on the pipeline
  # and sends anything that it receives.
  private def handle_pipeline
    spawn(name: "Pipeline loop") do
      loop do
        begin
          msg = @pipeline.receive
          # This probably needs a way to protect against message loops.
          send(message: msg)
        rescue e : Exception
          puts "pipeline handler"
          puts(e)
          puts e.backtrace.join("\n")
          exit
        end
      end
    end
  end

  private def handle_evaluations
    pipeline = subscribe(tags: ["evaluate()"])
    spawn(name: "Evaluation Handler") do
      loop do
        begin
          msg = pipeline.receive
          evaluation = @pending_evaluation[msg.parameters["uuid"]]
          evaluation.set(
            msg.parameters["receiver"],
            msg.parameters["relevance"],
            msg.parameters["certainty"]
          )
          if evaluation.finished?
            winner = evaluation.winner
            evaluation.message.evaluated = true
            winner.send evaluation.message if winner
            @pending_evaluation.delete msg.parameters["uuid"]
          end
        rescue e : Exception
          puts "evaluation handler"
          puts e
          puts e.backtrace.join("\n")
          exit
        end
      end
    end
  end

  # Subscribe a new message consumer to the Bus
  def subscribe(tags = [] of String)
    pipeline = Pipeline(Message).new(capacity: 10, origin: origin_tag)
    tags << pipeline.origin
    tags.each do |tag|
      @subscriptions[tag][pipeline] = true
    end
    @subscribers[pipeline] = tags
    pipeline
  end

  # Remove a message consumer from the Bus
  def unsubscribe(pipeline)
    if tags = @subscribers[pipeline]?
      tags.each do |tag|
        hsh = @subscriptions[tag]?
        hsh.delete(pipeline)
      end
      @subscribers.delete(pipeline)
    end
  end

  # Generate a message for this bus.
  def message(
    body : String,
    origin : String? = nil,
    tags : Array(String) = [] of String,
    parameters : Hash(String, String) = Hash(String, String).new
  )
    message_impl(
      body: [body],
      origin: origin,
      tags: tags,
      parameters: parameters
    )
  end

  def message(
    body : Array(String),
    origin : String? = nil,
    tags : Array(String) = [] of String,
    parameters : Hash(String, String) = Hash(String, String).new
  )
    message_impl(
      body: body,
      origin: origin,
      tags: tags,
      parameters: parameters
    )
  end

  def message_impl(
    body : Array(String),
    origin : String? = nil,
    tags : Array(String) = [] of String,
    parameters : Hash(String, String) = Hash(String, String).new
  )
    Message.new(
      body: body,
      parameters: parameters,
      tags: tags,
      origin: origin,
      pipeline: @pipeline,
      bus: self
    )
  end

  # Send a message to the subscribers
  def send(message : Message)
    # It's quite possible for tag combinations to target the same
    # recipient via multiple tags. In those cases the system should
    # only send a given message one time, so the following code builds
    # a unique list of recipients.
    receivers = Hash(Pipeline(Message), Bool).new
    message.tags.each do |tag|
      if @subscriptions.has_key?(tag)
        @subscriptions[tag].each_key do |receiver|
          receivers[receiver] = true
        end
      end
    end

    # This needs to do a two-step send. It needs to find out
    # which handlers are willing to handle the message, through
    # calling the handlers evaluate# methods, and then it needs
    # to pick one to actually send to.

    @pending_evaluation[message.uuid.to_s] = Evaluation.new(message, receivers.keys)

    receivers.keys.each do |receiver|
      receiver.send(message)
    end
  end
end
