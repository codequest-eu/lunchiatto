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
             :order_owner,
             :current_user_dish_price,
             :current_user_ordered_dish

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
  
  def order_owner
    object.user.name
  end

  def current_user_ordered_dish
    return "You didn't order any dish." if current_user_dish.blank?
    current_user_dish.name
  end
  
  def current_user_dish_price
    return "0.00" if current_user_dish.blank?
    current_user_dish.price.to_s
  end

  private

  def policy
    @policy ||= OrderPolicy.new(current_user, object)
  end
  
  def current_user_dish
    @current_user_dish ||= object.dishes.find_by(user: current_user)
  end
end
