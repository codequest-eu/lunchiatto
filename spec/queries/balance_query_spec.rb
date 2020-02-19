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
      subject { described_class.new(other_user).send(:pending_debts_dishes) }

      it 'returns hash of all debt users' do
        expect(subject).to eq(user.id => - other_dish.price_cents)
      end
    end

    context 'after orders_shipping_data' do
      subject { described_class.new(other_user).send(:orders_shipping_data) }

      it 'returns hash of orders data' do
        expect(subject)
          .to eq(order.id => {user_ids: [user.id, other_user.id],
                              shipping_cents: order.shipping_cents,
                              orderer_id: order.user.id})
      end
    end

    context 'after orders_user_share' do
      subject { described_class.new(other_user).send(:orders_user_share) }

      it 'returns hash with data of orders that user share' do
        expect(subject).to eq(order.id => {user_ids: [user.id, other_user.id],
                                           shipping_cents: order.shipping_cents,
                                           orderer_id: order.user.id})
      end
    end

    context 'after sum_of_user_shared_orders_shipping' do
      subject do
        described_class.new(other_user)
          .send(:sum_of_user_shared_orders_shipping)
      end

      it 'returns hash with sum of orders shipping data that user share' do
        expect(subject).to eq(user.id => - order.shipping_cents /
                                            order.ordering_users_count)
      end
    end

    context 'after pending_debts' do
      subject { described_class.new(other_user).send(:pending_debts) }

      it 'returns hash of total pending debts' do
        expect(subject).to eq(user.id => - other_dish.price_cents -
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
      subject { described_class.new(user).send(:credits_shipping_data) }

      it 'returns hash of orders data' do
        expect(subject).to eq(order.id => {user_ids: [user.id, other_user.id],
                                           shipping_cents: order.shipping_cents,
                                           orderer_id: order.user_id})
      end
    end

    context 'after shipping_by_user' do
      subject { described_class.new(user).send(:shipping_by_user) }

      it 'returns hash with sum of shipping cost for every user' do
        expect(subject).to eq(other_user.id => order.shipping_cents /
                                                order.ordering_users_count)
      end
    end

    context 'after pending_credits' do
      subject { described_class.new(user).send(:pending_credits) }

      it 'returns hash of total pending_credits' do
        expect(subject).to eq(other_user.id => other_dish.price_cents +
                                                order.shipping_cents /
                                                order.ordering_users_count)
      end
    end
  end

  context 'with 2 orders and 3 users' do
    let!(:order_2) do
      create :order, :with_ordered_status, user: user,
                                           company: company,
                                           shipping: '50.00'
    end
    let!(:user_3) { create :user, company: company }
    let!(:dish_3) { create :dish, order: order_2, price: '30.00' }
    let!(:user_dish_3) { create :user_dish, dish: dish_3, user: user_3 }
    let!(:dish_4) { create :dish, order: order_2, price: '50.00' }
    let!(:user_dish_4) { create :user_dish, dish: dish_4, user: user }
    let!(:user_dish_5) { create :user_dish, dish: dish_4, user: other_user }

    describe 'debts' do
      context 'after pending_debts_dishes' do
        let!(:user_subject) do
          described_class.new(user).send(:pending_debts_dishes)
        end
        let!(:other_user_subject) do
          described_class.new(other_user).send(:pending_debts_dishes)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:pending_debts_dishes)
        end

        it 'returns hash with dishes prices of all debt for specific user' do
          expect(user_subject).to eq({})
          expect(other_user_subject)
            .to eq(user.id => - other_dish.price_cents -
                                dish_4.price_cents /
                                dish_4.user_dishes_count)
          expect(user_3_subject).to eq(user.id => - dish_3.price_cents)
        end
      end

      context 'after orders_shipping_data' do
        let!(:user_subject) do
          described_class.new(user).send(:orders_shipping_data)
        end
        let!(:other_user_subject) do
          described_class.new(other_user).send(:orders_shipping_data)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:orders_shipping_data)
        end
        # rubocop:disable RSpec/ExampleLength
        it 'returns hash of orders data if user is in debt' do
          expect(user_subject).to eq({})
          expect(other_user_subject)
            .to eq(order.id => {user_ids: [user.id, other_user.id],
                                shipping_cents: order.shipping_cents,
                                orderer_id: order.user.id},
                   order_2.id => {user_ids: [user_3.id, other_user.id, user.id],
                                  shipping_cents: order_2.shipping_cents,
                                  orderer_id: order_2.user.id})
          expect(user_3_subject).to eq(other_user_subject)
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'after orders_user_share' do
        let!(:other_user_subject) do
          described_class.new(other_user).send(:orders_user_share)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:orders_user_share)
        end
        # rubocop:disable RSpec/ExampleLength
        it 'returns hash with filtered data of orders that user share ' do
          expect(other_user_subject)
            .to eq(order.id => {user_ids: [user.id, other_user.id],
                                shipping_cents: order.shipping_cents,
                                orderer_id: order.user.id},
                   order_2.id => {user_ids: [user_3.id, other_user.id, user.id],
                                  shipping_cents: order_2.shipping_cents,
                                  orderer_id: order_2.user.id})
          expect(user_3_subject)
            .to eq(order_2.id => {user_ids: [user_3.id, other_user.id, user.id],
                                  shipping_cents: order_2.shipping_cents,
                                  orderer_id: order_2.user.id})
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'after sum_of_user_shared_orders_shipping' do
        let!(:other_user_subject) do
          described_class.new(other_user)
            .send(:sum_of_user_shared_orders_shipping)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:sum_of_user_shared_orders_shipping)
        end
        # rubocop:disable RSpec/ExampleLength
        it 'returns hash with sum of orders shipping data of orders that
          user share' do
          expect(other_user_subject)
            .to eq(user.id => - order.shipping_cents /
                                order.ordering_users_count -
                                order_2.shipping_cents /
                                order_2.ordering_users_count)
          expect(user_3_subject)
            .to eq(user.id => - (order_2.shipping_cents.to_f /
                                 order_2.ordering_users_count).to_i)
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'after pending_debts' do
        let!(:other_user_subject) do
          described_class.new(other_user).send(:pending_debts)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:pending_debts)
        end
        # rubocop:disable RSpec/ExampleLength
        it 'return hash of total pending debt for specific user' do
          expect(other_user_subject)
            .to eq(user.id => - other_dish.price_cents -
                                dish_4.price_cents /
                                dish_4.user_dishes_count -
                                order.shipping_cents /
                                order.ordering_users_count -
                                order_2.shipping_cents /
                                order_2.ordering_users_count)
          expect(user_3_subject)
            .to eq(user.id => - dish_3.price_cents -
                                order_2.shipping_cents /
                                order_2.ordering_users_count)
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    describe 'credits' do
      context 'after pending_credits_prices' do
        let!(:other_user_subject) do
          described_class.new(other_user).send(:pending_credits_prices)
        end
        let!(:user_subject) do
          described_class.new(user).send(:pending_credits_prices)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:pending_credits_prices)
        end

        it 'return correct hash for specific user' do
          expect(user_subject).to eq(other_user.id => other_dish.price_cents +
                                                      dish_4.price_cents /
                                                      dish_4.user_dishes_count,
                                     user_3.id => dish_3.price_cents)
          expect(other_user_subject).to eq({})
          expect(user_3_subject).to eq({})
        end
      end

      context 'after credits_shipping_data' do
        let!(:other_user_subject) do
          described_class.new(other_user).send(:credits_shipping_data)
        end
        let!(:user_subject) do
          described_class.new(user).send(:credits_shipping_data)
        end
        let!(:user_3_subject) do
          described_class.new(user_3).send(:credits_shipping_data)
        end
        # rubocop:disable RSpec/ExampleLength
        it 'returns hash of orders which user paid for' do
          expect(user_subject)
            .to eq(order.id => {user_ids: [user.id, other_user.id],
                                shipping_cents: order.shipping_cents,
                                orderer_id: order.user_id},
                   order_2.id => {user_ids: [user_3.id, other_user.id, user.id],
                                  shipping_cents: order_2.shipping_cents,
                                  orderer_id: order_2.user.id})
          expect(other_user_subject).to eq({})
          expect(user_3_subject).to eq({})
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'after shipping_by_user' do
        let!(:user_subject) do
          described_class.new(user).send(:shipping_by_user)
        end

        it 'kekw' do
          expect(user_subject)
            .to eq(other_user.id => order.shipping_cents /
                                    order.ordering_users_count +
                                    order_2.shipping_cents /
                                    order_2.ordering_users_count,
                   user_3.id => order_2.shipping_cents /
                                order_2.ordering_users_count)
        end
      end

      context 'after pending_credits' do
        let!(:user_subject) { described_class.new(user).send(:pending_credits) }
        # rubocop:disable RSpec/ExampleLength
        it 'returns hash of total pending credits' do
          expect(user_subject)
            .to eq(other_user.id => other_dish.price_cents +
                                    dish_4.price_cents /
                                    dish_4.user_dishes_count +
                                    order.shipping_cents /
                                    order.ordering_users_count +
                                    order_2.shipping_cents /
                                    order_2.ordering_users_count,
                   user_3.id => dish_3.price_cents +
                                order_2.shipping_cents /
                                order_2.ordering_users_count)
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end
  end
end
