require 'curses'
require_relative 'account_thread'
require_relative 'command_handler'
require_relative 'curses_formattable.rb'
require_relative 'notification_thread'
require_relative 'order_thread'
require_relative 'stock_thread'
require_relative 'stock_watcher'
require 'broker_full/utils/properties'
require 'broker_full/services/shared/callable'
require 'broker_full/models/order'
require 'broker_full/models/stock_holding'

class StockThread
  include Shared::Callable, Curses, CursesFormattable
  attr_reader :account, :parent, :properties, :main

  def initialize(parent)
    @parent     = parent
    @account    = parent.account
    @properties = parent.properties
    @main       = parent.main
  end

  def start
    loop do
      begin
        stock_symbols = properties[:stock_symbols]
        next if stock_symbols.nil? || stock_symbols.empty?

        quotes = market_api.quote
        stocks_information(quotes)
        sleep_with_delay
      rescue StandardError => e
        # Eat error
      end
    end
  end

  def stocks_information(quotes)
    parent.quotes = quotes
    output_stocks(quotes)
  end

  def output_stocks(quotes)
    x_pos = 0
    main.setpos(4, x_pos)

    main.attron(color_pair(1)) { main << "Stocks Information       [#{Time.now.strftime('%m/%d/%Y')} #{Time.now.strftime('%I:%M:%S')}]" }
    new_line_pos(main)

    quotes.each do |quote|
      [-> { main.attron(color_pair(3)) { main << "[#{quote.symbol}] P: #{quote.price}  B: #{quote.bid_price}  A: #{quote.ask_price} %: #{quote.day_change_sign}#{quote.change_from_prior}" } }
      ].each do |cmd|
        cmd.call
        new_line_pos(main)
      end
    end

    main.refresh
  end

  def sleep_with_delay
    sleep(properties[:delays]['quotes'].to_i)
  end
end