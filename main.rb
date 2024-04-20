require 'broker_full/models/broker_manager'

class Main
  attr_reader :broker_manager

  def initialize
    @broker_manager = BrokerManager.new
  end

  def self.run
    new.run
  end

  def run
    broker_manager.begin_trading
  end
end
