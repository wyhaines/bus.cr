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

    def set(receiver, relevance, certainty)
      @evaluations[@lookup_table[receiver]] = Confidence.new(
        relevance: relevance.to_i,
        certainty: certainty.to_i
      )
    end

    def finished?
      !@evaluations.values.any? { |v| v.nil? }
    end

    def winner
      evl = @evaluations
      return nil unless finished?

      evl.to_a.sort_by { |pair| pair[1].not_nil! }.last.first
    end
  end
end
