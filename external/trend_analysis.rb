require '../simulation/main'

class TrendAnalysis
  attr_reader :market_date, :max_result, :symbol

  THREADS_MAX = 12

  def initialize(market_date, symbol)
    @market_date = market_date
    @max_result  = {}
    @symbol      = symbol
  end

  def self.analyze_trends(market_date, symbol)
    new(market_date, symbol).analyze_trends
  end

  def analyze_trends
    positive_range = { start: 1.0, end: 1.1, step: 0.00125 }
    negative_range = { start: 1.000, end: 0.97, step: 0.0125 }

    @max_result = { positive: positive_range[:start], negative: negative_range[:start], trends_minimum: 3, value: 0 }
    workers     = []

    (3 .. 14).step(1) do |trends_minimum|
      puts "Trends count: #{trends_minimum}"
      (positive_range[:start] .. positive_range[:end]).step(positive_range[:step]) do |positive|
        (negative_range[:end] .. negative_range[:start]).step(negative_range[:step]) do |negative|

          if workers.size == 14
            workers.map(&:join)
            workers = []
          end

          workers << Thread.new do
            result = Simulation::Main.run(market_date, symbol, negative, positive, trends_minimum)
            handle_result(negative, positive, trends_minimum, result)
          end
        end
      end
    end
  end

  def handle_result(negative, positive, trends_minimum, result)
    total_money = result.invested_amount.to_f + result.day_trading_available
    result      = { negative: negative, positive: positive, trends_minimum: trends_minimum, value: total_money }
    mutex       = Mutex.new

    mutex.synchronize do
      if total_money > max_result[:value]
        @max_result = result
        puts "*** MAX: #{@max_result}"
      end
    end
  end
end

TrendAnalysis.analyze_trends('2019-11-29', 'ENPH')