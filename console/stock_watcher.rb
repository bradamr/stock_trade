require 'curses'

require_relative 'account_thread'
require_relative 'command_handler'
require_relative 'curses_formattable'
require_relative 'notification_thread'
require_relative 'order_thread'
require_relative 'stock_thread'
require_relative 'stock_watcher'

class StockWatcher
  attr_reader :highest_prices, :parent
  MINIMUM_LOSS_PERCENTAGE = 0.9985

  def initialize(parent)
    @parent         = parent
    @account        = parent.account
    @highest_prices = {}
  end

  def self.run(parent)
    new(parent).run
  end

  def run
    loop do
      sleep 0.25
      holdings = parent.account&.holdings
      next if holdings.nil? || holdings.empty?

      holdings.each do |holding|
        # Get quote for particular symbol
        quote = parent.quote_by_symbol(holding.symbol)
        next unless quote

        check_highest_price(quote)
        check_on_loss(quote, holding)
      end
    end
  end

  private

    # This method will be used to determined cutoff points. E.g. if you have gains and the price begins to drop, use
    # the highest price as an anchor to judge a cutoff when to initialize a sale.
    def check_highest_price(quote)
      price                         = quote.price # Current market price
      highest_price                 = highest_prices[quote.symbol] # Highest recorded price

      @highest_prices[quote.symbol] = price unless highest_price # Record highest price if not previous recorded
      @highest_prices[quote.symbol] = price if highest_price && price > highest_price # Set highest price if current is higher
    end

    def check_on_loss(quote, holding)
      average_held_price = holding.average_price # Average price of holdings
      current_price      = quote.price # Current market price
      highest_price = highest_prices[quote.symbol]

      place_order_and_notify(:price_limit, quote, holding) if average_held_price * MINIMUM_LOSS_PERCENTAGE < current_price
      place_order_and_notify(:highest_price_limit, quote, holding) if current_price < highest_price * MINIMUM_LOSS_PERCENTAGE
    end

    def place_order_and_notify(notification_key_type, quote, holding)
      Order.new(Constants::ORDER_ACTIONS[:sell], account.id, quote.symbol, holding.quantity, quote.price)
      NotificationThread.notify(notification_key_type, "Stock value of [#{holding.symbol}] @ #{order.price} went below minimum threshold: #{}.")
      # Disabling for now to see how notifications view potential orders
      #Thread.new { OrderThread.order(order, parent.properties) }

      @highest_prices[quote.symbol] = nil if notification_key_type == :highest_price_limit
    end

end