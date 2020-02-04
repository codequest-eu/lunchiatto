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

  # TODO: fix this
  def pending_debts
    @pending_debts ||= Dish
      .joins(:order, :user_dishes)
      .where(
        'orders.status = 1 AND orders.user_id != ? AND user_dishes.user_id = ?',
        user.id, user.id
      )
      .group('orders.user_id')
      .pluck('orders.user_id, SUM(-price_cents/user_dishes_count) - SUM(shipping_cents)/SUM(user_dishes_count)')
      .to_h
  end

  def pending_credits
    Dish
      .joins(:order, :user_dishes)
      .where(
        'orders.status = 1 AND orders.user_id = ? AND user_dishes.user_id != ?',
        user.id, user.id
      )
      .group('user_dishes.user_id')
      .pluck('user_dishes.user_id, SUM(price_cents/user_dishes_count) + SUM(shipping_cents)/SUM(user_dishes_count)')
      .to_h
  end
end
