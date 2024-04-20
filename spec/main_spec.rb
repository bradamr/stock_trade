require 'spec_helper'
require_relative '../main'

describe Main do
  subject { described_class.new }

  describe '.run' do
    it 'creates instance and executes #run' do
      expect(described_class).to receive(:new).and_return(subject)
      expect(subject).to receive(:run)

      described_class.run
    end
  end

  describe '#run' do
    let(:broker_double) { double(:broker_with_mode, begin_trading: true)}

    before { allow(subject).to receive(:broker_manager).and_return(broker_double) }

    it 'starts trading using the broker manager' do
      expect(broker_double).to receive(:begin_trading)

      subject.run
    end
  end
end
