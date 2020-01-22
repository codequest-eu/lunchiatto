# frozen_string_literal: true
class OrderSerializer < ActiveModel::Serializer
  attributes :amount,
             :current_user_ordered,
             :date,
             :deletable,
             :dishes_count,
             :editable,
             :from,
             :from_today,
             :id,
             :ordered_by_current_user,
             :shipping,
             :status,
             :total,
             :user_id,
             :current_user_dish,
             :who_ordered,
             :current_user_dish_price

  has_many :dishes
  has_one :user

  def shipping
    object.shipping.to_s
  end

  def amount
    object.amount.to_s
  end

  def dishes
    object.dishes.by_name
  end

  def total
    (object.amount + object.shipping).to_s
  end

  def include_dishes?
    !options[:shallow]
  end

  def include_user?
    !options[:shallow]
  end

  def editable
    policy.update?
  end

  def deletable
    policy.destroy?
  end

  def current_user_ordered
    object.dishes.find_by(user: current_user).present?
  end

  def ordered_by_current_user
    object.user == current_user
  end

  def from_today
    object.from_today?
  end
  
  def who_ordered
    object.user.name
  end

  def current_user_dish
    if current_user_ordered_dish?
      object.dishes.where('dishes.user_id = ?', current_user.id).first.name
    else
      "You didn't order any dish."
    end
  end
  
  def current_user_dish_price
    if current_user_ordered_dish?
      object.dishes.where('dishes.user_id = ?', current_user.id).first.price.to_s
    else
      "0.00"
    end
  end

  private

  def policy
    @policy ||= OrderPolicy.new(current_user, object)
  end
  
  def current_user_ordered_dish?
    !object.dishes.where('dishes.user_id = ?', current_user.id).empty?
  end
end
