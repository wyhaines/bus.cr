class Bus
  struct Confidence
    getter relevance : Int32
    getter certainty : Int32
    getter force : Bool?

    def initialize(
      relevance : Int32 = 0,
      certainty : Int32 = 0
    )
      @relevance = relevance
      @certainty = certainty
      @force = nil
    end

    def initialize(
      @relevance : Int32 = 0,
      @certainty : Int32 = 0,
      @force : Bool? = nil
    )
    end

    def initialize(@force : Bool? = nil)
      @relevance = 0
      @certainty = 0
    end

    def <=>(val : Confidence) : Int32
      rel = @relevance
      base_comparison = rel <=> val.relevance

      if base_comparison.zero?
        cert = @certainty
        cert <=> val.certainty
      else
        base_comparison
      end
    end
  end
end
