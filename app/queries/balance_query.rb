# frozen_string_literal: true

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
    @pending_debts ||= Dish
      .joins(:order)
      .where(
        "orders.status = 1 AND " \
        "orders.user_id != #{user.id} AND " \
        "dishes.user_id = #{user.id}"
      )
      .group('orders.user_id')
      .pluck('orders.user_id, SUM(-price_cents - shipping_cents/dishes_count)')
      .to_h
  end

  def pending_credits
    Dish
      .joins(:order)
      .where(
        "orders.status = 1 AND " \
        "orders.user_id = #{user.id} AND " \
        "dishes.user_id != #{user.id}"
      )
      .group('dishes.user_id')
      .pluck('dishes.user_id, SUM(price_cents + shipping_cents/dishes_count)')
      .to_h
  end
end
