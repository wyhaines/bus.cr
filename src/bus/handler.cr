require "./pipeline"

class Bus
  abstract class Handler
    @pipeline : Bus::Pipeline(Bus::Message)?
    @listener_proc : Fiber? = nil
    getter bus : Bus

    def initialize(@bus, tags = [] of String)
      @handle_counter = 0_u64
      @evaluate_counter = 0_u64
      @pipeline = register_handler(tags)
      @listener_proc = nil
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
    abstract def evaluate(msg)
    abstract def handle(msg)

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

    def listen
      spawn(name: "Generic Handler Listen Loop") do
        ppl = @pipeline
        loop do
          begin
            msg = ppl.receive if !ppl.nil?
            if !msg.nil?
              if msg.evaluated
                @handle_counter += 1
                handle(msg)
              else
                @evaluate_counter += 1
                evaluate(msg)
              end
            end
          rescue e : Exception
            puts "#{e}\n\n#{e.backtrace.join("\n")}" # TODO: Better exception logging
          end
        end
      end
    end
  end
end
