# frozen_string_literal: true
class UserSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :subtract_from_self,
             :account_balance,
             :account_number,
             :total_debt,
             :pending_debt,
             :pending_transfers_count,
             :company_admin,
             :company_id,
             :pending_orders_count,
             :current_user,
             :debt_permitted

  def total_debt
    object.total_debt.to_s
  end

  def pending_debt
    object.pending_debt.to_s
  end

  def account_balance
    scope.payer_balance(object).to_s
  end

  def include_account_balance?
    instance_options[:with_balance]
  end

  def current_user
    object.id == scope.id
  end

  def debt_permitted
    object.total_debt.to_f > Dish::MAX_DEBT
  end
end
