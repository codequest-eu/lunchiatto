# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many(:orders) }
  it { should have_many(:user_balances) }
  it { should have_many(:balances_as_payer) }
  it { should have_many(:submitted_transfers) }
  it { should have_many(:received_transfers) }
  it { should have_many(:user_dishes) }
  it { should have_many(:dishes) }
  it { should belong_to(:company) }
  it { should callback(:add_first_balance).after(:create) }

  let(:user) { create(:user) }
  let(:payer) { create(:other_user) }
  let!(:balance_one) do
    create :user_balance, user: user, payer: payer, balance: 15
  end
  let!(:balance_two) do
    create :user_balance, user: user, payer: payer, balance: 17
  end
  let!(:balance_three) do
    create :user_balance, user: user, payer: user, balance: 34
  end

  let!(:payment_one) do
    create :payment, user: user, payer: payer, balance: 15
  end
  let!(:payment_two) do
    create :payment, user: user, payer: payer, balance: 2
  end

  describe '#balances' do
    it 'returns adequate non-zero balances' do
      allow(user)
        .to receive(:company)
        .and_return(instance_double('Company', users: [user, payer]))
      balances = user.balances
      expect(balances.count).to be(1)
    end
  end

  describe '#add_first_balance' do
    let(:user) { described_class.new }
    let(:balances) { class_double('UserBalance') }

    it 'creates a user_balance' do
      expect(balances).to receive(:create).with(balance: 0, payer: user)
      expect(user).to receive(:user_balances).and_return(balances)
      user.add_first_balance
    end
  end

  describe '#subtract' do
    let(:money) { Money.new 1200, 'PLN' }
    it 'add a new reduced user balance' do
      expect(user).to receive(:payer_balance).with(payer)
        .and_return(Money.new(5000, 'PLN'))
      expect { user.subtract(money, payer) }
        .to change(user.user_balances, :count).by(1)
    end

    it 'doesnt reduce when subtract_from_self is false' do
      expect(user).to receive(:subtract_from_self).and_return(false)
      expect(user).not_to receive(:payer_balance).with(user)
      expect { user.subtract(money, user) }
        .not_to change(user.user_balances, :count)
    end

    it 'does reduce when subtract_from_self is true' do
      expect(user).to receive(:payer_balance)
        .with(user).and_return(Money.new(5000, 'PLN'))
      expect(user).to receive(:subtract_from_self).and_return(true)
      expect { user.subtract(money, user) }
        .to change(user.user_balances, :count).by(1)
    end
  end

  describe '#to_s' do
    it 'calls name' do
      expect(user).to receive(:name).and_return('mock name')
      expect(user.to_s).to eq('mock name')
    end
  end

  describe '#total_debt' do
    it 'returns proper balance' do
      money = Money.new(-1700, 'PLN')
      expect(user.total_debt).to eq(money)
    end
  end

  # TODO(anyone): deprecated method - remove
  describe '#total_debt' do
    it 'returns proper balance' do
      money = Money.new(-1700, 'PLN')
      expect(user.total_debt).to eq(money)
    end
  end

  describe '#debt_to and #payer_balance' do
    let(:user_2) { create :other_user, email: 'janek@yolo.com' }

    let!(:payment_three) do
      create(:payment, user: user_2, payer: payer, balance: 100)
    end

    it 'returns debt_to of user_2 and correct payer_balance of payer' do
      expect(user_2.debt_to(payer)).to eq(Money.new(-10_000, 'PLN'))
      expect(payer.payer_balance(user_2)).to eq(Money.new(10_000, 'PLN'))
    end
  end

  describe '#pending_orders_exist' do
    let!(:order) do
      create :order, :with_ordered_status, user: user
    end
    let!(:dish) { create :dish, order: order }
    let!(:user_dish) { create :user_dish, user: user, dish: dish }

    it "returns 'true' when pending order exist" do
      expect(user.pending_orders_exist).to eq(true)
    end

    it "returns 'false' when order changes status to 'delivered'" do
      order.change_status(2)
      order.save
      expect(user.pending_orders_exist).to eq(false)
    end
  end

  describe '#pending_transfers_count' do
    let!(:transfer_one) { create :transfer, from: user, to: payer }
    let!(:transfer_two) { create :transfer, from: payer, to: user }
    it 'returns adequate count' do
      expect(user.pending_transfers_count).to eq(1)
    end
  end

  describe 'admin scope' do
    let(:admin) { create :user, admin: true, email: 'admin@adminbook.com' }
    before do
      user
      payer
      admin
    end
    it 'Only returns admin' do
      expect(described_class.admin.count).to be(1)
    end
  end
end
