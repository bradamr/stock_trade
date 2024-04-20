require_relative '../spec_helper'
require_relative '../../models/order'
require_relative '../../models/constants'

describe Order do
  let(:actions) { { buy:  Constants::ORDER_ACTIONS[:buy],
                    sell: Constants::ORDER_ACTIONS[:sell] } }
  let(:account_id) { '12345678' }
  let(:options) { { symbol: 'XYZ', quantity: 100, price: 1.23 } }
  let(:current_action) { actions[:buy] }
  let(:order) { described_class.new(current_action, account_id,
                                    options[:symbol], options[:quantity], options[:price])  }

  subject { order }

  describe '#buy?' do
    subject { order.buy? }
    it { is_expected.to be_truthy }

    context 'when sell action passed' do
      let(:current_action) { actions[:sell] }
      it { is_expected.to be_falsey }
    end
  end

  describe '#sell?' do
    subject { order.sell? }
    it { is_expected.to be_falsey }

    context 'when buy action passed' do
      let(:current_action) { actions[:sell] }
      it { is_expected.to be_truthy }
    end
  end

  describe '#valid?' do
    subject { order.valid? }

    context 'when action is not a value of "buy" or "sell"' do
      let(:current_action) { 'haggle' }
      it { is_expected.to be_falsey }
    end

    context 'when account ID not present' do
      let(:account_id) {}
      it { is_expected.to be_falsey }
    end

    context 'when symbol is not present' do
      before { options[:symbol] = nil }
      it { is_expected.to be_falsey }
    end

    context 'when quantity is not present' do
      before { options[:quantity] = nil}
       it { is_expected.to be_falsey }
    end

    context 'when price is not present' do
      before { options[:price] = nil}
      it { is_expected.to be_falsey }
    end
  end
end
