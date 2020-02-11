# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Dish, type: :model do
  it { should belong_to(:order) }
  it { should validate_presence_of(:price_cents) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:order) }
  it { should validate_length_of(:name).is_at_most(255) }

  let(:company) { create :company }
  let(:user) { create :user, company: company }
  let(:other_user) { create :other_user, company: company }
  let(:order) { create :order, user: user, company: company }
  let!(:dish) { create :dish, order: order, price_cents: 1200 }
  let!(:user_dish) { create :user_dish, user: user, dish: dish }
  let(:new_dish) { dish.dup }
  let!(:new_user_dish) { create :user_dish, user: other_user, dish: new_dish }

  it 'monetizes price' do
    expect(monetize(:price_cents)).to be_truthy
  end

  describe '#copy' do
    it 'returns an instance of dish' do
      expect(new_dish.users.first).to eq(other_user)
      expect(new_dish.name).to eq(dish.name)
      expect(new_dish.order).to eq(order)
    end
  end

  describe '#subtract' do
    before do
      Dish.reset_counters(new_dish.id, :user_dishes)
    end

    it 'reduces users balance' do
      shipping = Money.new(1000, 'PLN') / order.ordering_users_count
      dish.subtract shipping, other_user
      expect(user.balances.first.balance.cents)
        .to eq(- dish.price_cents - shipping.cents)
      expect(other_user.balances.first.balance.cents)
        .to eq(new_dish.price_cents + shipping.cents)
    end
  end
end
