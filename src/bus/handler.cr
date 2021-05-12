require "./pipeline"

class Bus
  abstract class Handler
    @pipeline : Bus::Pipeline(Bus::Message)?
    @listener_proc : Fiber? = nil
    @handle_counter : Atomic(UInt64) = Atomic.new(0_u64)
    @evaluate_counter : Atomic(UInt64) = Atomic.new(0_u64)
    getter bus : Bus

    def initialize(
      @bus : Bus,
      tags : Array(String) = [] of String
    )
      @pipeline = register_handler(tags)
    end

    private def register_handler(tags : Array(String))
      @bus.subscribe(
        tags: ["handler", "handler:#{self.class.name}"] + tags
      )
    end

    def run
      @listener_proc = listen
    end

    # All implementations of
    abstract def evaluate(msg : Bus::Message)
    abstract def handle(msg : Bus::Message)

    # This method determines if the handler will handle the message. It
    # checks `#can_handle?` to see if the handler is able to handle the
    # message, and `#authorized_to_handle?` to see if the handler has
    # permission to handle the message.
    def will_handle?(msg)
      can_handle?(msg) && authorized_to_handle?(msg)
    end

    # This should probably be overridden in subclasses so that they can make
    # informed decisions about whether or not they can handle the message.
    def can_handle?(msg)
      true
    end

    # Override this if only certain users should be authorized to have access
    # to the given handler.
    def authorized_to_handle?(msg)
      true
    end

    # This method spawns a fiber to listen for messages being sent to the hander.
    # The base functionality of the listen loop is encapsulated in this method, and
    # most users should not have to override this method. However, if one must
    # override it, then the user implemented method should do the following:
    # 1. `spawn()` a new fiber to do the work.
    # 2. `loop do` inside the fiber to eternally listen for connections.
    # 3. Check if @pipeline is nil, and if it is, `sleep 1;next`
    # 4. Preferably within a `begin`/`rescue` section:
    #    a. `#receive` a message from the pipeline.
    #    b. If the message is non-nil, call `handle_received_message` with the receives message as an argument.

    def listen
      spawn(name: "Generic Handler Listen Loop: #{self}") do
        loop do
          ppl = @pipeline
          if ppl.nil?
            # It would be very unusual for execution to reach this spot without
            # having a pipeline, but if it does, the code will bail out, sleep,
            # and check in a second to see if it has a pipeline to listen to.
            sleep 1
            next
          end

          begin
            msg = ppl.receive
            if !msg.nil?
              handle_received_message(message: msg)
            end
          rescue e : Exception
            puts "#{e}\n\n#{e.backtrace.join("\n")}" # TODO: Better exception logging
          end
        end
      end
    end

    # The base functionality of this method is to just determine if the message
    # is being received for evaluation or for handling. If you override this
    # method, ensure that `#call_evaluate` is invoked with the message as an
    # argument if the message does not have it's `evaluated` flag set, and that
    # `#call_handle` be invoked if the `evaluated` flage is set.

    protected def handle_received_message(message : Bus::Message)
      if message.evaluated
        call_handle(message)
      else
        call_evaluate(message)
      end
    end

    # This method increments the handled counter, and calls the `#handle`
    # method. It should be called any time the handler needs to handle a
    # message.
    private def call_handle(message : Bus::Message)
      @handle_counter.add(1)
      handle(message)
    end

    # This method increments the evaluated counter, and calls the `#evaluate`
    # method. It should be called any time the handler needs to evaluate a
    # message.
    private def call_evaluate(message : Bus::Message)
      @evaluate_counter.add(1)
      evaluate(message)
    end

    # Return the number of times that this handler has handled a message.
    def handled_count
      @handle_counter.get
    end

    # Return the number of times that this handler has evaluated a message.
    def evaluated_count
      @evaluate_counter.get
    end
  end
end
