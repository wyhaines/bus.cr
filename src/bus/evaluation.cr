require "./confidence"
require "./message"
require "./pipeline"

class Bus
  class Evaluation
    getter message : Message
    getter evaluations : Hash(Pipeline(Message), Confidence?) = Hash(Pipeline(Message), Confidence?).new
    getter start_time : Time::Span
    property timeout : Float64

    # Build an Evaluation object. It takes two arguments. The first is the
    # message that requires a destination. The second is the list of pipelines
    # connecting to the potential receivers for the message.
    #
    # A lookup table is built that contains the origin string for each pipeline
    # as the key, and the pipeline itself as the value. A second hash
    # is built which pairs the pipelines to the Confidence objects for
    # each receiver.
    def initialize(@message, receivers, @timeout = 10.0)
      @lookup_table = Hash(String, Pipeline(Message)).new
      receivers.each do |receiver|
        @lookup_table[receiver.origin] = receiver
        @evaluations[receiver] = nil
      end
      @start_time = Time.monotonic
    end

    # Takes the origin string for a receiver, and the relevance,
    # certainty, and force values, and sets them inside of the Evaluation
    # object.
    def set(
      receiver : String,
      relevance : String | Int = 0,
      certainty : String | Int = 0,
      force : String = ""
    )
      if force == ""
        force_value = nil
      elsif force[0].downcase == 't'
        force_value = true
      elsif force[0].downcase == 'f'
        force_value = false
      else
        force_value = nil
      end

      @evaluations[@lookup_table[receiver]] = Confidence.new(
        relevance: relevance.to_i,
        certainty: certainty.to_i,
        force: force_value
      )
    end

    # Determine if this evaluation has timed out. If, for some reason,
    # one of the handlers is very slow returning their Confidence, or
    # never returns a Confidence, the evaulation should still be
    # evaluated using all of the entries that responded by the time that
    # the timeout is exceeded.
    def timed_out?
      (Time.monotonic - @start_time) > @timeout.seconds
    end

    # Returns true if evaluations have been received for all of the
    # receivers which were provided when the object was created.
    # This also evaluates to true if the timeout period has been exceeded.
    def finished?
      # timed_out? || !@evaluations.values.any? { |v| v.nil? }
      !@evaluations.values.any? { |v| v.nil? }
    end

    # Determine the winners of the evaluation. The algorithm is as follows:
    #
    # 1. All receivers with a Confidence `force` value of false are automatically losers.
    # 2. All receivers with a Confidence `force` value of true are automatically winners.
    # 3. For all others are sorted by `relevance` and then by `certainty.
    # 4. Winners are everything with `force==true` plus everything with the highest `relevance` and `certainty`.
    def winners
      # First, collect everything as a array of arrays, removing any that
      # never had their Confidence objects set.
      evl = @evaluations.to_a
      return Array(Pipeline(Message)).new unless finished?

      if @message.strategy == Bus::Message::Strategy::All
        # All matches everything that doesn't have force==false.
        filter_by_strategy(
          evl.reject do |pair|
            pl = pair.last
            pl && pl.force == false
          end.map(&.first)
        )
      else
        # Get everything that has explicitly opted in.
        winners = evl.select do |pair|
          pl = pair.last
          pl && pl.force
        end.map(&.first)

        # Get rid of everything that has force set, as well as
        # everything that is nil, leaving only those with actual
        # confidence settings.
        sorted = evl.select do |pair|
          pl = pair.last
          pl && pl.force.nil?
        end.sort_by { |pair| pair.last.not_nil! }

        top_winner = sorted.first.last.not_nil!

        filter_by_strategy(
          winners + sorted.select do |pair|
            pl = pair.last
            pl && (pl.relevance == top_winner.relevance &&
              pl.certainty == top_winner.certainty)
          end.map(&.first)
        )
      end
    end

    def filter_by_strategy(winners)
      case @message.strategy
      when Bus::Message::Strategy::RandomWinner
        filter_random_winners(winners)
      when Bus::Message::Strategy::FirstWinner
        filter_first_winners(winners)
      when Bus::Message::Strategy::AllWinners, Bus::Message::Strategy::All
        filter_all_winners(winners)
      else
        filter_random_winners(winners)
      end
    end

    private def filter_random_winners(winners)
      [winners.shuffle.first]
    end

    private def filter_first_winners(winners)
      [winners.first]
    end

    private def filter_all_winners(winners)
      winners
    end
  end
end
