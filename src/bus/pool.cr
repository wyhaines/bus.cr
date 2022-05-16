require "./do_proxy"
require "./future_proxy"

class Bus
  class Pool(H)
    getter bus : Bus
    getter handler : H.class
    getter handlers : Array(H) = Array(H).new
    property min : Int32
    property max : Int32

    def initialize(@handler, @min = 1, @max = 5, initial = 1, @bus = Bus.new)
      initialize_impl(count: initial) do
        @handler.new
      end
    end

    def initialize(@handler, @min = 1, @max = 5, initial = 1, @bus = Bus.new, &initializer)
      initialize_impl(count: initial, initializer: initializer)
    end

    def initialize_impl(count, &initializer)
      count.times do
        handlers << initializer.call
      end
    end

    def do
      DoProxy(H).new(self)
    end

    def do
      yield DoProxy(H).new(self)
    end

    def await
      FutureProxy(H).new(self)
    end

    def await
      yield FutureProxy(H).new(self)
    end
  end
end
