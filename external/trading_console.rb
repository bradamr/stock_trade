require 'curses'

require_relative '../utils/properties'
require_relative '../modules/callable'
require_relative '../models/order'

class TradingConsole
  include Callable, Curses
  attr_reader :account, :command, :properties, :refresh_account, :refresh_stocks, :stocks, :win

  FORMATTING = {
      blinking:   Curses::A_BLINK,
      bold:       Curses::A_BOLD,
      normal:     Curses::A_NORMAL,
      underlined: Curses::A_UNDERLINE
  }

  COLORS = {
      black: Curses::COLOR_BLACK,
      blue:  Curses::COLOR_BLUE,
      red:   Curses::COLOR_RED,
      white: Curses::COLOR_WHITE
  }

  OPTIONS = [['A', 'Refresh Account'], ['B', 'Buy'], ['BM', 'Buy MAX'], ['S', 'Sell'], ['SM', 'Sell MAX'], ['R', 'Refresh All'], ['Q', 'Quit']]

  def initialize
    setup_params
    initialize_formatting
    @win        = Curses::Window.new(0, 0, 1, 2)
    @properties = Utils::Properties.load('brokers/live/ally.yml')

    @refresh_account = true
    @refresh_stocks  = true
  end

  def self.run
    new.run
  end

  def run
    begin
      loop do
        external_data
        reset_all
        show_title
        show_options
        show_information
        refresh
        handle_input(command_input)
      end
    rescue StandardError => e
      puts "Error encontered: #{e.message}/#{e.backtrace}"
    ensure
      close_screen
    end
  end

  private

  def reset_all
    win.clear
  end

  def refresh
    set_input_line
    win.refresh
  end

  def external_data
    @account = account_api.info if refresh_account
    @stocks  = market_api.quote if refresh_stocks

    @refresh_account = false
    @refresh_stocks  = false
  end

  def show_options
    OPTIONS.each do |option|
      format_option(option.first, option.last)
      add_horizontal_space
    end

    new_line_pos(2)
  end

  def add_horizontal_space
    win.setpos(win.cury, win.curx + 3)
  end

  def format_option(key, description)
    win.attron(color_pair(1)) { win << "[#{key}]" }
    win.attron(color_pair(3)) { win << ' - ' + description }
  end

  def show_title
    win.attron(color_pair(1)) { win << 'Stock Trading Options' + (' ' * 93) }
    new_line_pos
  end

  def show_information
    stocks_information
    account_information
  end

  def account_information
    win.attron(color_pair(1)) { win << 'Account Information' }
    new_line_pos

    [-> { win.attron(color_pair(3)) { win << '[DT Available] ' + account.day_trading_available.to_s } },
     -> { win.attron(color_pair(3)) { win << '[DT SOD] ' + account.day_trading_start_of_day.to_s } },
     -> { win.attron(color_pair(3)) { win << '[Cash] ' + account.cash_available.to_s } }
    ].each { |cmd| cmd.call; add_horizontal_space }
    new_line_pos

    [-> { win.attron(color_pair(3)) { win << '[Cost Basis] ' + account.invested_amount.to_s } },
     -> { win.attron(color_pair(3)) { win << '[Holdings] ' + (account.holdings.empty? ? 'None' : account.holdings.map { |h| "#{h.symbol}: #{h.quantity} @ #{h.cost_basis}" }.join(", ")) } }
     ].each { |cmd| cmd.call; add_horizontal_space }
     new_line_pos(3)
  end

  def stocks_information
    win.attron(color_pair(1)) { win << 'Stocks Information' }
    new_line_pos

    win.attron(color_pair(3)) { win << "[Symbol] #{stocks.first.symbol}" }; add_horizontal_space
    win.attron(color_pair(3)) { win << "[Time] #{Time.now.strftime('%H:%M:%S')}" }
    new_line_pos
    win.attron(color_pair(3)) { win << "[Price] #{stocks.first.price}   [Bid] #{stocks.first.bid_price}    [Ask] #{stocks.first.ask_price}    [Max Purchasable] #{max_purchasable}" }
    new_line_pos(3)
  end

  def setup_params
    init_screen # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on
    start_color # Initializes the color attributes for terminals that support it.
    curs_set(0) # Hides the cursor
    #noecho # Disables characters typed by the user to be echoed by Curses.getch as they are typed.
    init_pair 1, 1, 0
  end

  def command_input
    win.getstr.to_s
  end

  def account_refresh
    @refresh_account = true
  end

  def stocks_refresh
    @refresh_stocks = true
  end

  def handle_input(entered_command)
    @command = entered_command
    case entered_command
      when /^a$/i
        account_refresh
      when /^b \d+$/i
        buy_stocks(pull_number_from_str(entered_command))
      when /^bm$/i
        buy_stocks_max
      when /^q$/i
        exit 0
      when /^r$/i
        stocks_refresh
      when /^s \d+$/i
        sell_stocks(pull_number_from_str(entered_command))
      when /^sm$/i
        sell_stocks_max
      else
        # Do nothing
    end
  end

  def max_purchasable
    (account.day_trading_available / stocks.first.bid_price).floor
  end

  def buy_stocks_max
    buy_stocks(max_purchasable)
  end

  def sell_stocks_max
    sell_stocks(account.holdings.map { |h| h.quantity }.reduce(:+))
  end

  def buy_stocks(quantity)
    return unless quantity.is_a? Integer

    order = Order.new(1, account.id, stocks.first.symbol, quantity, stocks.first.bid_price)
    send_order order
  end

  def sell_stocks(quantity)
    return unless quantity.is_a? Integer

    order = Order.new(2, account.id, stocks.first.symbol, quantity, stocks.first.bid_price)
    send_order order
  end

  def send_order(order)
    win.setpos(20,0)
    win << order.inspect
    win.refresh
    sleep 5
      #order_api.send(order) if properties[:trades_enabled].downcase == 'y' # Sends order to Ally
  end

  def pull_number_from_str(str)
    str.match(/\d+/).to_s.to_i
  end

  def initialize_formatting
    Curses.init_pair(1, COLORS[:white], COLORS[:blue])
    Curses.init_pair(2, COLORS[:blue], COLORS[:black])
    Curses.init_pair(3, COLORS[:white], COLORS[:black])
  end

  def columns
    Curses.cols
  end

  def rows
    Curses.lines
  end

  def set_input_line
    win.setpos(rows - 2, 0)
    win.attron(color_pair(1)) { win << '~>' }
  end

  def new_line_pos(times = 1)
    x = 0
    y = win.cury + (times * 1)

    win.setpos(y, x)
  end
end