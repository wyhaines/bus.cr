require "csuuid"
require "./pipeline"

class Bus
  struct Message
    getter body : Array(String)
    getter tags : Array(String)
    getter parameters : Hash(String, String)
    getter origin : String?
    getter pipeline : Pipeline(Message)
    getter uuid : CSUUID
    property evaluated : Bool = false

    def initialize(
      @pipeline,
      @bus : Bus,
      @body = [""],
      @tags = [] of String,
      @parameters = Hash(String, String).new,
      @origin = nil,
      @uuid = CSUUID.new
    )
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
        @bus.message(
          body: body,
          parameters: parameters,
          tags: tags,
          origin: origin
        )
      )
    end

    def send_evaluation(relevance, certainty, receiver, uuid = @uuid)
      reply_impl(
        @bus.message(
          body: "",
          tags: ["evaluate()"],
          parameters: {
            "relevance" => relevance.to_s,
            "certainty" => certainty.to_s,
            "receiver"  => receiver,
            "uuid"      => uuid.to_s,
          },
          origin: origin)
      )
    end
  end
end
