require 'broker_full/models/account'

module Simulation
  class AccountService
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def can_purchase?(price)
      account.day_trading_available > price.to_f
    end

    def shares_owned?(symbol)
      account.shares_owned(symbol).positive?
    end
  end
end