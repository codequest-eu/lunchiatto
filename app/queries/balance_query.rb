# frozen_string_literal: true
# rubocop:disable ClassLength
# rubocop:disable MethodLength
class BalanceQuery
  def initialize(user)
    @user = user
  end

  def pending_balances
    pending_debts.merge(pending_credits) { |_, debt, credit| debt + credit }
  end

  private

  attr_reader :user

  def pending_debts
    pending_debts_dishes
      .merge(sum_of_user_shared_orders_shipping) do |_key, a_value, b_value|
      a_value + b_value
    end
  end

  def pending_debts_dishes
    Dish
      .joins(:order, :user_dishes)
      .where(
        'orders.status = 1 AND orders.user_id != ? AND user_dishes.user_id = ?',
        user.id, user.id
      )
      .group('orders.user_id')
      .pluck('orders.user_id, SUM(-price_cents/user_dishes_count)')
      .to_h
  end

  def orders_shipping_data
    debts = {}

    UserDish
      .eager_load(dish: :order)
      .where(orders: {status: 1})
      .where.not(orders: {user_id: user.id})
      .pluck('orders.id,
        orders.shipping_cents,
        user_dishes.user_id,
        orders.user_id')
      .uniq
      .each do |order_id, shipping_cents, user_id, orderer_id|
      if debts.key?(order_id)
        debts[order_id][:user_ids] << user_id
      else
        debts[order_id] = {
          user_ids: [user_id],
          shipping_cents: shipping_cents,
          orderer_id: orderer_id,
        }
      end
    end
    debts
  end

  def orders_user_share
    debts = {}
    orders_shipping_data.each do |key, order_data|
      next unless order_data[:user_ids].include?(user.id)
      debts[key] = {
        user_ids: order_data[:user_ids],
        shipping_cents: order_data[:shipping_cents],
        orderer_id: order_data[:orderer_id],
      }
    end
    debts
  end

  def sum_of_user_shared_orders_shipping
    debts = Hash.new 0
    orders_user_share.each do |_, order_data|
      debts[order_data[:orderer_id]] += -
        (order_data[:shipping_cents].to_f /
        order_data[:user_ids].count).to_i
    end
    debts
  end

  def pending_credits
    pending_credits_prices.merge(shipping_by_user) do |_key, a_value, b_value|
      a_value + b_value
    end
  end

  def pending_credits_prices
    Dish
      .joins(:order, :user_dishes)
      .where(
        'orders.status = 1 AND orders.user_id = ? AND user_dishes.user_id != ?',
        user.id, user.id
      )
      .group('user_dishes.user_id')
      .pluck('user_dishes.user_id, SUM(price_cents/user_dishes_count)')
      .to_h
  end

  def credits_shipping_data
    debts = {}
    UserDish
      .eager_load(dish: :order)
      .where('orders.status = 1 AND orders.user_id = ?',
             user.id)
      .pluck('orders.id,
        orders.shipping_cents,
        user_dishes.user_id,
        orders.user_id')
      .uniq
      .each do |order_id, shipping_cents, user_id, orderer_id|
      if debts.key?(order_id)
        debts[order_id][:user_ids] << user_id
      else
        debts[order_id] = {
          user_ids: [user_id],
          shipping_cents: shipping_cents,
          orderer_id: orderer_id,
        }
      end
    end
    debts
  end

  def shipping_by_user
    data = Hash.new 0
    credits_shipping_data.each do |_, order_data|
      order_data[:user_ids].each do |user_id|
        next if user_id == order_data[:orderer_id]
        data[user_id] +=
          order_data[:shipping_cents] / order_data[:user_ids].count
      end
    end
    data
  end
end
