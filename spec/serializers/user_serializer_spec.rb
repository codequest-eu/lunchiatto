# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserSerializer do
  let(:user) { instance_double('User') }
  let(:current_user) { instance_double('User') }
  let(:serializer) { described_class.new(user, scope: current_user) }
  let(:extended_serializer) { described_class.new(user, with_balance: true) }

  it '#total_debt' do
    expect(user).to receive(:total_debt) { 12 }
    expect(serializer.total_debt).to eq('12')
  end

  it '#account_balance' do
    expect(current_user).to receive(:payer_balance).with(user) { 12 }
    expect(serializer.account_balance).to eq('12')
  end

  describe '#include_account_balance?' do
    it 'returns false by default' do
      expect(serializer.include_account_balance?).to be_falsey
    end
    it 'returns true with :current_user_balance option' do
      expect(extended_serializer.include_account_balance?).to be_truthy
    end
  end
end
