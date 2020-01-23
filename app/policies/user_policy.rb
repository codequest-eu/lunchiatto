# frozen_string_literal: true
class UserPolicy < ApplicationPolicy
  def destroy?
    return false if user == record
    user.company_admin?
  end
end
