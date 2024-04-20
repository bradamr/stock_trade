require 'curses'
require_relative 'account_thread'
require_relative 'command_handler'
require_relative 'curses_formattable'
require_relative 'notification_thread'
require_relative 'order_thread'
require_relative 'stock_thread'
require_relative 'stock_watcher'

require 'broker_full'

class Console
  include Curses, CursesFormattable
  attr_accessor :quotes, :account
  attr_reader :account, :account_retriever, :input, :input_handler, :main, :properties, :quote_retriever, :quotes

  def initialize
    @input = stdscr.subwin(3, cols - 1, stdscr.maxy - 3, 1)
    @main  = stdscr

    @properties = Utils::Properties.load('brokers/live/ally.yml')
    @quotes     = properties[:stock_symbols]

    @account_retriever = AccountThread.new(self)
    @input_handler     = CommandHandler.new(self)
    @quote_retriever   = StockThread.new(self)
  end

  def self.run
    new.run
  end

  def run
    setup_screen
    set_formatting
    draw_base

    Thread.new { account_retriever.start }
    Thread.new { quote_retriever.start }
    Thread.new { StockWatcher.run(self) }

    begin
      loop do
        main.refresh
        setup_input_box
        command = input.getstr
        input_handler.handle(command)
        input.clear
      end
    rescue StandardError => e
    ensure
      Curses.close_screen
    end
  end

  def quote_by_symbol(symbol)
    quotes.select { |q| q.symbol.downcase == symbol.downcase }.first
  end

  def holding_by_symbol(symbol)
    account.holdings.select { |h| h.symbol.downcase == symbol.downcase }.first
  end

  def quantity_of(symbol)
    holding_by_symbol(symbol).quantity
  end

  private

  def setup_input_box
    input.setpos(1, 1)
    input.box('|', '*')
  end

  def setup_screen
    init_screen # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on
    start_color # Initializes the color attributes for terminals that support it.
    curs_set(0) # Hides the cursor
  end

  def draw_base
    show_title
    show_options
  end

  def show_title
    main.setpos(0, 0)
    main.attron(color_pair(1)) { main << 'Stock Trading Options' + (' ' * 93) }
  end

  def show_options
    main.setpos(1, 0)

    CursesFormattable::OPTIONS.each_with_index do |option, index|
      format_option(main, option.first, option.last)
      add_horizontal_space(main)
      new_line_pos(main) if (index + 1) % 5 == 0
    end
  end
end

Console.run