# frozen_string_literal: true
class DishPolicy < ApplicationPolicy
  def create?
    user_debt_permitted? || order_by_current_user?
  end

  def update?
    order.in_progress? && (record_belongs_to_user? || order_by_current_user?)
  end

  def show?
    true
  end

  def destroy?
    order.in_progress? && record_belongs_to_user?
  end

  def copy?
    order.in_progress? && !record_belongs_to_user? &&
      (user_debt_permitted? || order_by_current_user?)
  end

  private

  def order
    @order ||= record.order
  end

  def order_by_current_user?
    order.user_id == user.id
  end

  def user_debt_permitted?
    Balance.new(user).total_debt > Money.new(-Dish::MAX_DEBT, 'PLN')
  end
end
