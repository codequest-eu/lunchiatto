# frozen_string_literal: true
class DishPolicy < ApplicationPolicy
  def create?
    user_debt_permitted? || order_by_current_user?
  end

  def update?
    (order.in_progress? && record_belongs_to_user?) ||
      (order.ordered? && order_by_current_user?)
  end

  def show?
    true
  end

  def destroy?
    order.in_progress? && record_belongs_to_user?
  end

  def copy?
    order.in_progress? &&
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
    Balance.new(user).total_debt.to_f > Dish::MAX_DEBT
  end

  def record_belongs_to_user?
    record.users.include?(user) &&
      record.user_dishes.find_by(user_id: user.id).dish_owner
  end
end
