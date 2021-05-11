require "csuuid"
require "./pipeline"

class Bus
  struct Message
    enum Strategy
      All
      AllWinners
      RandomWinner
      FirstWinner
    end

    getter body : Array(String)
    getter tags : Array(String)
    getter parameters : Hash(String, String)
    getter origin : String?
    getter pipeline : Pipeline(Message)
    getter uuid : CSUUID
    getter strategy : Strategy
    property evaluated : Bool = false

    def initialize(
      @pipeline : Pipeline(Message),
      # @bus : Bus,
      @body : Array(String) = [""],
      @tags : Array(String) = [] of String,
      @parameters : Hash(String, String) = Hash(String, String).new,
      @origin : String? = nil,
      @uuid : CSUUID = CSUUID.new,
      @strategy : Strategy = Strategy::RandomWinner
    )
    end

    def initialize(
      @pipeline : Pipeline(Message),
      body : String,
      @tags : Array(String) = [] of String,
      @parameters : Hash(String, String) = Hash(String, String).new,
      @origin : String? = nil,
      @uuid : CSUUID = CSUUID.new,
      @strategy : Strategy = Strategy::RandomWinner
    )
      @body = [body]
    end

    private def reply_impl(message : Message)
      @pipeline.send(message)
    end

    def reply(message : Message)
      reply_impl(message)
    end

    def reply(
      body = "",
      parameters : Hash(String, String) = Hash(String, String).new,
      tags = [] of String
    )
      local_origin = @origin
      tags << local_origin if !local_origin.nil?
      reply(
        body: [body],
        parameters: parameters,
        tags: tags
      )
    end

    def reply(
      body = [""],
      parameters : Hash(String, String) = Hash(String, String).new,
      tags = [] of String
    )
      local_origin = @origin
      tags << local_origin if !local_origin.nil?
      reply_impl(
        self.class.new(
          body: body,
          parameters: parameters,
          tags: tags,
          origin: origin,
          pipeline: @pipeline
        )
      )
    end

    def send_evaluation(
      receiver,
      relevance = 0,
      certainty = 0,
      force = nil,
      uuid = @uuid
    )
      reply_impl(
        self.class.new(
          body: "",
          tags: ["evaluate()"],
          parameters: {
            "relevance" => relevance.to_s,
            "certainty" => certainty.to_s,
            "force"     => force.to_s,
            "receiver"  => receiver,
            "uuid"      => uuid.to_s,
          },
          origin: origin,
          pipeline: @pipeline)
      )
    end
  end
end
