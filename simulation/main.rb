require 'date'
require 'broker_full/models/account'
require_relative 'account_service'
require 'broker_full/models/decision'
require 'broker_full/utils/properties'
require 'broker_full/models/quote'
require 'broker_full/models/stock_holding'
require 'broker_full/services/stock_service'
require 'broker_full/utils/stock_historical_data'

module Simulation
  class Main
    attr_reader :account, :account_service, :output, :properties, :stock_service

    def initialize(negative, positive, trends_min, output)
      @properties                         = Utils::Properties.load('brokers/live/ally.yml')
      properties[:thresholds]['negative'] = negative if negative
      properties[:thresholds]['positive'] = positive if positive
      properties[:minimum_trends]         = trends_min if trends_min

      @account         = Account.new('1234567', 50000, 90000, 90000, nil)
      @account_service = Simulation::AccountService.new(account)
      @stock_service   = StockService.new(properties)
      @output          = output
    end

    def self.run(market_date, symbol, negative = nil, positive = nil, trends_min = nil, output = false)
      new(negative, positive, trends_min, output).run(market_date, symbol)
    end

    def run(market_date, symbol)
      StockHistoricalData.single_day(symbol, market_date, nil) do |record|
        price = record['price']
        time  = DateTime.strptime(record['trade_time'][0, 10], '%s')

        last_price = stock_service.data.latest_price(symbol)

        if last_price.to_f != price.to_f
          quote = Quote.new(symbol, price, time.to_s)
          stock_service.data.add(quote)
          handle_decision(symbol)
        end
      end

      puts "Final: #{account}" if output
      account
    end

    def handle_decision(symbol)
      choice                = Decision.make(stock_service.analysis, stock_service.data, account_service, symbol)
      price                 = stock_service.data.latest_price(symbol)
      day_trading_available = account.day_trading_available
      stocks_purchasable    = (day_trading_available / price).floor
      stocks_owned          = account.holding(symbol)&.quantity

      #puts Decision.full_info(price, stock_service.analysis, account_service, symbol) if output

      case choice
        when :pm
          cost_basis                     = price * stocks_purchasable
          account._day_trading_available = account.day_trading_available - cost_basis
          account._holdings              = [StockHolding.new(symbol, stocks_purchasable, cost_basis)]
        when :sm
          account._day_trading_available = account.day_trading_available + (price * stocks_owned)
          account._holdings              = []
      end
    end
  end
end

Simulation::Main.run('2019-10-31', 'ENPH', 0.9992, 1.015, 5, true)