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
  end
end
