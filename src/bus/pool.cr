class Bus
  class Pool(H)
    getter bus : Bus

    def initialize(@bus = Bus.new)
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