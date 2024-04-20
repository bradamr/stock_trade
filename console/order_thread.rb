require 'curses'

require_relative 'account_thread'
require_relative 'command_handler'
require_relative 'curses_formattable'
require_relative 'notification_thread'
require_relative 'order_thread'
require_relative 'stock_thread'
require_relative 'stock_watcher'


class OrderThread
  include Shared::Callable
  attr_reader :order, :properties

  def initialize(order, properties)
    @order      = order
    @properties = properties
  end

  def self.order(order, properties)
    new(order, properties).send_order
  end

  def send_order
    order_api.send(order) if properties[:trades_enabled] == 'Y'
  end
end