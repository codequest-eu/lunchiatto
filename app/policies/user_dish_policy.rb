# frozen_string_literal: true
class UserDishPolicy < ApplicationPolicy
  def create?
    record.user_debt_permitted?
  end

  def update?
    record_belongs_to_user
  end
  
  def destroy?
    record_belongs_to_user
  end
  
  def copy?
    record_belongs_to_user
  end
end
