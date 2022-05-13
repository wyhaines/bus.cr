class Bus
  class Pool(H)
    getter bus : Bus
    getter handler : H.class
    property min : Int32
    property max : Int32

    def initialize(@handler, @min = 1, @max = 5, initial = 1, @bus = Bus.new)
    end

    def initialize(@handler, @min = 1, @max = 5, initial = 1, @bus = Bus.new, &initializer)
    end

    def do
      DoProxy.new
    end

    def do
      yield DoProxy.new
    end

    def await
      FutureProxy.new
    end

    def await
      yield FutureProxy.new
    end
  end
end
