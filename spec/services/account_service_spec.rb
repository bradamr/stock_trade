require_relative '../spec_helper'
require_relative '../../models/account'
require_relative '../../models/stock_holding'
require_relative '../../services/account_service'

describe AccountService do
  let(:account) { Account.new('12345678', 50000, 100000, 100000, account_holdings) }
  let(:account_holdings) { [StockHolding.new('ABC', 100), StockHolding.new('DEF', 250)] }
  let(:account_api) { double(:account_api, info: '') }
  let(:account_service) { double(:account_service, refresh: '') }
  let(:api_factory) { double(:api_factory) }
  let(:properties) { double(:properties) }

  subject { described_class.new(properties) }

  before do
    allow(Api::Factory).to receive(:new).with(anything).and_return(api_factory)
    allow(api_factory).to receive(:account).and_return(account_api)
  end

  describe '#refresh' do
    it 'calls account api to refresh data' do
      expect(account_api).to receive(:info)
      subject.refresh
    end
  end

  describe '#holdings_for' do
    before { allow(subject).to receive(:account).and_return(account) }

    it 'uses account data to pull holding by symbol' do
      expect(account).to receive(:holding).with(anything)
      subject.holdings_for('ABC')
    end
  end

  describe '#purchasable_shares' do
    let(:investable_cash) { 50000 }
    let(:price) { 20.15 }

    it 'calls #investable_cash to get amount' do
      expect(subject).to receive(:investable_cash).and_return(investable_cash)
      subject.purchasable_shares(price)
    end

    it 'calls #stocks_purchasable with expected params' do
      expect(subject).to receive(:investable_cash).and_return(investable_cash)
      expect(subject).to receive(:stocks_purchasable).with(investable_cash, price)
      subject.purchasable_shares(price)
    end

  end

  describe '#can_purchase?' do
    let(:investable_cash) { 50000 }
    let(:price) { 20.15 }
    let(:properties) { { maximum_cash_investment: 50000 } }

    before do
      allow(subject).to receive(:properties).and_return(properties)
      allow(subject).to receive(:account).and_return(account)
    end

    it 'calls #investable_cash to get amount' do
      expect(subject).to receive(:within_cash_limit?).and_return(true)
      expect(subject).to receive(:investable_cash).and_return(investable_cash)
      subject.can_purchase?(price)
    end

    it 'calls #within_cash_limit? to see if within range' do
      expect(subject).to receive(:within_cash_limit?).and_call_original
      subject.can_purchase?(price)
    end

    context 'with insufficient investable money' do
      let(:investable_cash) { 0 }

      it 'returns false' do
        expect(subject).to receive(:within_cash_limit?).and_return(true)
        expect(subject).to receive(:investable_cash).and_return(investable_cash)
        result = subject.can_purchase?(price)
        expect(result).to be_falsey
      end
    end

    context 'with sufficient investable money' do
      it 'returns true' do
        expect(subject).to receive(:within_cash_limit?).and_return(true)
        expect(subject).to receive(:investable_cash).and_return(investable_cash)
        result = subject.can_purchase?(price)
        expect(result).to be_truthy
      end
    end

    context 'when not within cash limit' do
      it 'returns false' do
        expect(subject).to receive(:within_cash_limit?).and_return(false)
        result = subject.can_purchase?(price)
        expect(result).to be_falsey
      end
    end
  end

  describe '#shares_owned?' do
    before { allow(subject).to receive(:account).and_return(account) }

    context 'stock holdings are in account' do
      it 'returns true' do
        result = subject.shares_owned?('ABC')
        expect(result).to be_truthy
      end
    end

    context 'stock holdings are not in account' do
      it 'returns false' do
        result = subject.shares_owned?('XYZ')
        expect(result).to be_falsey
      end
    end
  end

  describe '#within_cash_limit?' do
    context 'when no cash limit defined in properties' do
      let(:properties) { { maximum_cash_investment: '' } }

      it 'returns true' do
        result = subject.within_cash_limit?
        expect(result).to be_truthy
      end
    end

    context 'when cash limit defined in properties' do
      let(:properties) { { maximum_cash_investment: 4500 } }
      let(:investable_cash) { 5000 }
      let(:sod_trading_balance) { 10000 }
      let(:trading_balance) { 500 }

      before do
        allow(subject).to receive(:account).and_return(account)
        account._day_trading_available = trading_balance
        account._day_trading_start_of_day = sod_trading_balance
      end

      context 'when maximum cash amount is already invested' do
        it 'returns false' do
          result = subject.within_cash_limit?
          expect(result).to be_falsey
        end
      end

      context 'when maximum cash amount is not invested' do
        let(:trading_balance) { 9000 }

        it 'returns true' do
          result = subject.within_cash_limit?
          expect(result).to be_truthy
        end
      end
    end
  end

  describe '#cash_limit_exists?' do
    let(:properties) { { maximum_cash_investment: 4500 } }

    it 'returns true' do
      result = subject.cash_limit_exists?
      expect(result).to be_truthy
    end

    context 'when maximum cash investment not defined' do
      let(:properties) { { maximum_cash_investment: nil } }

      it 'returns false' do
        result = subject.cash_limit_exists?
        expect(result).to be_falsey
      end
    end

  end

  describe '#investable_cash_limit' do
    let(:properties) { { maximum_cash_investment: 4500 } }

    it 'returns maximum cash investment' do
      result = subject.investable_cash_limit
      expect(result).to eq(properties[:maximum_cash_investment].to_f)
    end

    context 'when maximum cash investment not defined' do
      let(:properties) { { maximum_cash_investment: nil } }

      it 'returns false' do
        result = subject.investable_cash_limit
        expect(result).to be_falsey
      end
    end

    context 'when maximum cash investment is an empty string' do
      let(:properties) { { maximum_cash_investment: '' } }

      it 'returns false' do
        result = subject.investable_cash_limit
        expect(result).to be_falsey
      end
    end
  end

  describe '#investable_cash' do
    let(:properties) { { maximum_cash_investment: 4500 } }
    let(:investable_cash) { 5000 }
    let(:sod_trading_balance) { 10000 }
    let(:trading_balance) { 500 }

    context 'when cash limit exists' do
      before { allow(subject).to receive(:cash_limit_exists?).and_return(true) }

      it 'returns investable cash limit' do
        result = subject.investable_cash
        expect(result).to eq(properties[:maximum_cash_investment].to_f)
      end
    end

    context 'when cash limit does not exist' do
      let(:properties) { { maximum_cash_investment: nil } }

      before do
        allow(subject).to receive(:account).and_return(account)
        account._day_trading_available = trading_balance
      end

      it 'returns day trading balance' do
        result = subject.investable_cash
        expect(result).to eq(trading_balance)
      end
    end
  end
end
