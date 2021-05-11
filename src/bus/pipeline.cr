require "csuuid"

class Bus
  # A pipeline is just a channel with an extra origin tag that can
  # be used to uniquely identify this particular pipeline.
  class Pipeline(T) < Channel(T)
    property origin : String

    def initialize(capacity = 0, origin : String = CSUUID.new.to_s)
      @origin = origin
      super(capacity)
    end

    # Clear everything that is currently in the pipeline.
    def clear
      @lock.lock
      q = @queue
      q && q.clear
    ensure
      @lock.unlock
    end

    # Get a count of how many items are currently in the pipeline.
    def size : Int32
      @lock.lock
      q = @queue
      q ? q.size : 0
    ensure
      @lock.unlock
    end

    def <=>(val)
      self.origin <=> val.origin
    end
  end
end
