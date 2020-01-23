# frozen_string_literal: true
class BalanceSerializer < ActiveModel::Serializer
  attributes :balance,
             :pending_balance,
             :created_at,
             :user,
             :user_id

  def balance
    object.balance.to_s
  end

  def pending_balance
    object.pending_balance.to_s
  end

  def user
    object.user.name
  end

  def user_id
    object.user.id
  end

  def created_at
    object.created_at
  end
end
