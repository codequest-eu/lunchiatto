# frozen_string_literal: true
class CompanySerializer < ActiveModel::Serializer
  attributes :name
  has_many :users
  has_many :invitations

  def users
    object.users.by_name.active
  end
end
