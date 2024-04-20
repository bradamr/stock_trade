require 'curses'
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

class AccountThread
  include Shared::Callable, Curses, CursesFormattable
  attr_reader :account, :parent, :properties, :main

  def initialize(parent)
    @account    = []
    @parent     = parent
    @properties = parent.properties
    @main       = parent.main
  end

  def start
    loop do
      begin
        @account       = account_api.info
        parent.account = account
        account_information
        sleep_with_delay
      rescue StandardError => e
        # do nothing
      end
    end
  end

  private

  def account_information
    x_pos = 0
    main.setpos(15, x_pos)
    main.attron(color_pair(1))
    main << 'Account Information' + (' ' * 12)

    show_balances
    show_holdings
  end

  def show_balances
    x_pos = 0
    main.attron(color_pair(3))

    main.setpos(16, x_pos)

    [-> { main << 'DT: ' + account.day_trading_available.to_s }, # Day Trading Power
     -> { main << '  DTSOD: ' + account.day_trading_start_of_day.to_s }, # Start of Day - Day Trading Power
     -> { main << 'Cash: ' + account.cash_available.to_s }, # Cash
     -> { main << ' Cost Basis: ' + account.invested_amount.to_s } # Cost Basis
    ].each { |cmd| cmd.call; add_horizontal_space(main, 2) }
    new_line_pos(main, x_pos)

    main.refresh
  end

  def show_holdings
    x_pos = 0
    main.setpos(10, x_pos)
    main.attron(color_pair(1))
    main << 'Holdings'
    new_line_pos(main, x_pos)

    holdings = account.holdings

    main.attron(color_pair(3))
    main << 'None' + (' ' * 20) if holdings.empty?

    holdings.map { |h| "#{h.symbol}: #{h.quantity} @ #{h.cost_basis.round(3)} (#{(h.average_price).round(2)}) [#{cost_basis_difference(h.quantity, h.cost_basis, parent.quote_by_symbol(h.symbol))}]" }.each do |holding|
      main << holding
      new_line_pos(main, x_pos)
    end unless holdings.empty?

    main.refresh
  end
  def cost_basis_difference(holding_quantity, holding_cost_basis, quote)
    cost_difference = (holding_quantity * quote.price) - holding_cost_basis
    return "+#{cost_difference}" if cost_difference.positive?

    cost_difference
  end

  def sleep_with_delay
    sleep(properties[:delays]['balances'].to_i)
  end
end