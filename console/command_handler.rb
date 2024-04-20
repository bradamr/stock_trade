require_relative 'account_thread'
require_relative 'command_handler'
require_relative 'curses_formattable'
require_relative 'notification_thread'
require_relative 'order_thread'
require_relative 'stock_thread'
require_relative 'stock_watcher'

require 'broker_full/utils/properties'
require 'broker_full/services/shared/callable'
require 'broker_full/models/order'
require 'broker_full/models/stock_holding'

class CommandHandler
  include Shared::Callable, CursesFormattable
  attr_reader :input, :main, :parent, :properties

  def initialize(parent)
    @parent     = parent
    @input      = parent.input
    @main       = parent.main
    @properties = parent.properties
  end

  def handle(entered_command)
    number = nil
    symbol = nil

    begin
      number = pull_number_from_str(entered_command)
      symbol = pull_symbol_from_str(entered_command).upcase
    rescue Exception => e
      return unless entered_command =~ /^q.*$/i # Eat error
    end

    case entered_command
      when /^b\s{1}/i
        buy_stocks(number, symbol)
      when /^bm\s{1}/i
        buy_stocks_max(symbol)
      when /^q.*$/i
        exit 0
      when /^s\s{1}/i
        sell_stocks(number, symbol)
      when /^sm\s+/i
        sell_stocks_max(symbol)
      when /^w\s{1}/i
        watch_stock(symbol)
      when /^u\s{1}/i
        unwatch_stock(symbol)
      else
        # Do nothing
    end
  end

  private

  def clear_quotes(quotes)
    main.setpos(5, 0)

    (quotes.count + 1).times do
      main << (' ' * 42)
      new_line_pos(main)
    end
  end

  def watch_stock(symbol)
    stock_symbols = properties[:stock_symbols]
    return if stock_symbols.include?(symbol.upcase)

    stock_symbols              += ',' + symbol
    properties[:stock_symbols] = stock_symbols
  end

  def unwatch_stock(symbol)
    symbols_arr                       = properties[:stock_symbols].split(",")
    symbols_arr                       -= [symbol.upcase]
    parent.properties[:stock_symbols] = symbols_arr.join(',')
    clear_quotes(symbols_arr)
  end

  def send_order(order)
    Thread.new { OrderThread.order(order, properties) }
  end

  def pull_number_from_str(str)
    str.match(/\s+\d+$/).to_s.strip.to_i
  end

  def pull_symbol_from_str(str)
    str.match(/\s\w+(\s)?/).to_s.strip
  end

  def max_purchaseable(symbol)
    parent.quote_by_symbol(symbol)
  end

  def buy_stocks_max(symbol)
    max_stocks_purchasable = max_purchaseable(symbol)
    buy_stocks(max_stocks_purchasable, symbol)
  end

  def buy_stocks(quantity, symbol)
    return unless quantity.is_a?(Integer) && quantity.positive?
    quote = parent.quote_by_symbol(symbol)
    order = Order.new(1, parent.account.id, symbol, quantity, quote.bid_price)
    send_order(order)
  end

  def sell_stocks_max(symbol)
    quantity = parent.quantity_of(symbol)
    sell_stocks(quantity, symbol)
  end

  def sell_stocks(quantity, symbol)
    return unless quantity.is_a?(Integer) && quantity.positive?

    quote = parent.quote_by_symbol(symbol)
    order = Order.new(2, parent.account.id, symbol, quantity, quote.bid_price)
    send_order(order)
  end
end