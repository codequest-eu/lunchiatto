# frozen_string_literal: true
class UserForSelectSerializer < ActiveModel::Serializer
  attributes :name, :id, :account_number, :current_user, :debt_permitted
end
