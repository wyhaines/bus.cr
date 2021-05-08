require "./confidence"
require "./message"
require "./pipeline"

class Bus
  class Evaluation
    getter message : Message
    getter evaluations : Hash(Pipeline(Message), Confidence?) = Hash(Pipeline(Message), Confidence?).new

    def initialize(@message, receivers)
      @lookup_table = Hash(String, Pipeline(Message)).new
      receivers.each do |receiver|
        @lookup_table[receiver.origin] = receiver
        @evaluations[receiver] = nil
      end
    end

    def set(receiver, relevance = 0, certainty = 0, force : Bool? = nil)
      @evaluations[@lookup_table[receiver]] = Confidence.new(
        relevance: relevance.to_i,
        certainty: certainty.to_i,
        force: force
      )
    end

    def finished?
      !@evaluations.values.any? { |v| v.nil? }
    end

    def winners
      evl = @evaluations.to_a
      return nil unless finished?

      # Get everything that has explicitly opted in.
      winners = evl.select { |pair| pair.last.force }

      # Get rid of everything that has force set, leaving only
      # those with actual confidence settings.
      evl.reject! { |pair| !pair.last.force.nil? }

      sorted == evl.sort_by { |pair| pair.last.not_nil! }
      top_winner = sorted.first.last

      winners + sorted.select do |pair|
        pair.relevance == top_winner.relevance &&
          pair.certainty == top_winner.certainty
      end
    end
  end
end
