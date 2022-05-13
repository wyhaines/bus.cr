class Bus
  class Future(T)
    class NotReadyError < Exception; end

    struct Cancel; end

    getter toggle : Channel(T | Cancel) = Channel(T | Cancel).new
    property! value : T? = nil
    getter ready : Bool = false
    getter listener : Fiber

    def initialize
      @listener = spawn do
        val = @toggle.receive
        unless ready
          @value = val.as(T)
          ready!
        end
      end
    end

    def ready!
      @ready = true
    end

    def value
      if @ready
        @value
      else
        raise Bus::Future::NotReadyError.new
      end
    end

    def value=(val)
      @value = val
      ready!
      toggle.send(Cancel.new) # If value is set without using the listener, then we want to kill the listener.
    end
  end
end
