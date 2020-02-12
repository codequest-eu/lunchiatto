# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BalanceQuery do
  let!(:company) { create :company }
  let!(:user) { create :user, company: company }
  let!(:other_user) { create :other_user, company: company }
  let!(:order) do
    create :order, :with_ordered_status, user: user,
                                         company: company,
                                         shipping: '7.00'
  end
  let!(:dish) { create :dish, order: order, price: '20.00' }
  let!(:user_dish) { create :user_dish, user: user, dish: dish }
  let!(:other_dish) { create :dish, order: order, price: '25.00' }
  let!(:other_user_dish) do
    create :user_dish, user: other_user, dish: other_dish
  end

  describe 'pending_balances' do
    subject { described_class.new(user).pending_balances }

    it 'return correct pending balances towards specific user' do
      expect(subject[other_user.id].to_i)
        .to eq(other_dish.price_cents +
          order.shipping_cents / order.ordering_users_count)
    end

    context 'after order changes status to "delivered"' do
      before do
        order.change_status('delivered')
        order.save
      end

      it 'resets pending_balance' do
        expect(subject[other_user.id]).to eq(nil)
      end

      it "updates total_debt's" do
        expect(user.total_debt).to eq(0)
        expect(-other_user.total_debt.cents)
          .to eq(other_dish.price_cents +
            order.shipping_cents / order.ordering_users_count)
      end
    end

    context 'when dishes are shared' do
      let!(:another_user) { create :user, company: company }
      let!(:another_user_dish) do
        create :user_dish, dish: dish, user: another_user
      end

      it 'returns correct pending_balances' do
        expect(subject[another_user.id].to_i)
          .to eq(dish.price_cents / dish.user_dishes_count +
            order.shipping_cents / order.ordering_users_count)
      end
    end
  end

  describe 'debts' do
    context 'after pending_debts_dishes' do
      let!(:pending_debts_dishes) do
        described_class.new(other_user).send(:pending_debts_dishes)
      end

      it 'returns hash of all debt users' do
        expect(pending_debts_dishes).to eq(user.id => - other_dish.price_cents)
      end
    end

    context 'after orders_shipping_data' do
      let!(:orders_shipping_data) do
        described_class.new(other_user).send(:orders_shipping_data)
      end

      it 'returns hash of orders data' do
        expect(orders_shipping_data)
          .to eq(order.id => {user_ids: [user.id, other_user.id],
                              shipping_cents: order.shipping_cents,
                              orderer_id: order.user.id})
      end
    end

    context 'after orders_user_share' do
      let!(:orders_user_share) do
        described_class.new(other_user).send(:orders_user_share)
      end

      it 'returns hash with data of orders that user share' do
        expect(orders_user_share)
          .to eq(order.id => {user_ids: [user.id, other_user.id],
                              shipping_cents: order.shipping_cents,
                              orderer_id: order.user.id})
      end
    end

    context 'after sum_of_user_shared_orders_shipping' do
      let!(:sum_of_user_shared_orders_shipping) do
        described_class.new(other_user)
          .send(:sum_of_user_shared_orders_shipping)
      end

      it 'returns hash with sum of orders shipping data that user share' do
        expect(sum_of_user_shared_orders_shipping)
          .to eq(user.id => - order.shipping_cents /
                                order.ordering_users_count)
      end
    end

    context 'after pending_debts' do
      let!(:pending_debts) do
        described_class.new(other_user).send(:pending_debts)
      end

      it 'returns hash of total pending debts' do
        expect(pending_debts).to eq(user.id => - other_dish.price_cents -
                                                order.shipping_cents /
                                                order.ordering_users_count)
      end
    end
  end

  describe 'credits' do
    context 'after pending_credits_prices' do
      let!(:pending_credits_prices_empty) do
        described_class.new(other_user).send(:pending_credits_prices)
      end
      let!(:pending_credits_prices) do
        described_class.new(user).send(:pending_credits_prices)
      end

      it "is empty for user that wasn't payer" do
        expect(pending_credits_prices_empty).to eq({})
      end

      it 'returns hash of how much other users owe in dish prices ' do
        expect(pending_credits_prices)
          .to eq(other_user.id => other_dish.price_cents)
      end
    end

    context 'after credits_shipping_data' do
      let!(:credits_shipping_data) do
        described_class.new(user).send(:credits_shipping_data)
      end

      it 'returns hash of orders data' do
        expect(credits_shipping_data)
          .to eq(order.id => {user_ids: [user.id, other_user.id],
                              shipping_cents: order.shipping_cents,
                              orderer_id: order.user_id})
      end
    end

    context 'after shipping_by_user' do
      let!(:shipping_by_user) do
        described_class.new(user).send(:shipping_by_user)
      end

      it 'returns hash with sum of shipping cost for every user' do
        expect(shipping_by_user)
          .to eq(other_user.id => order.shipping_cents /
                                  order.ordering_users_count)
      end
    end

    context 'after pending_credits' do
      let!(:pending_credits) do
        described_class.new(user).send(:pending_credits)
      end

      it 'returns hash of total pending_credits' do
        expect(pending_credits).to eq(other_user.id => other_dish.price_cents +
                                                order.shipping_cents /
                                                order.ordering_users_count)
      end
    end
  end
end
