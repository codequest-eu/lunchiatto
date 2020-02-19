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
             :current_user_debt_permitted,
             :order_owner,
             :current_user_ordered_dishes,
             :current_user_dishes_price,
             :current_user_shipping_cost,
             :ordering_users_count

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
    object
      .dishes
      .joins(:user_dishes)
      .where('user_dishes.user_id = ?', current_user)
      .present?
  end

  def ordered_by_current_user
    object.user == current_user
  end

  def current_user_debt_permitted
    current_user.total_debt.to_f > Dish::MAX_DEBT
  end

  def from_today
    object.from_today?
  end

  def order_owner
    object.user.name
  end

  def current_user_ordered_dishes
    current_user_dishes.map(&:name).join(', ') || "You didn't order any dish."
  end

  def current_user_dishes_price
    return '0.00' if current_user_dishes.blank?
    current_user_dishes
      .pluck('SUM(price_cents/user_dishes_count)')[0].to_s.insert(-3, '.')
  end

  def current_user_shipping_cost
    return object.shipping.to_s if object.ordering_users_count == 0
    (object.shipping / object.ordering_users_count).to_s
  end

  private

  def policy
    @policy ||= OrderPolicy.new(current_user, object)
  end

  def current_user_dishes
    @current_user_dishes ||= object
      .dishes
      .joins(:user_dishes)
      .where('user_dishes.user_id = ?', current_user)
  end
end
