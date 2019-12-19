# frozen_string_literal: true

class PaymentQuery
  def initialize(user)
    @user = user
  end

  def debts
    all_users
    grouped_by_id
    having_sum
    pluck_balance.to_h
  end

  def balances
    all_users
    grouped_by_id
    pluck_balance.to_h
  end

  private

  attr_reader :user, :query

  def all_users
    @query =
      Payment.where(
        "(user_id = #{user.id} OR payer_id = #{user.id}) " \
        "AND user_id != payer_id"
      )
  end

  def grouped_by_id
    @query =
      query.group(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END"
      )
  end

  def having_sum
    @query =
      query.having(
        "SUM(CASE WHEN user_id = #{user.id} THEN -balance_cents " \
        "WHEN payer_id = #{user.id} THEN balance_cents END) < 0"
      )
  end

  def pluck_balance
    @query =
      query.pluck(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END, " \
        "SUM(CASE WHEN user_id = #{user.id} THEN -balance_cents " \
        "WHEN payer_id = #{user.id} THEN balance_cents END)"
      )
  end
end
