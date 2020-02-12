# frozen_string_literal: true
class Dish < ActiveRecord::Base
  has_many :user_dishes, dependent: :destroy
  has_many :users, through: :user_dishes

  belongs_to :order, counter_cache: true

  validates :name, presence: true,
                   length: {maximum: 255}

  validates :order, :price_cents, presence: true

  register_currency :pln
  monetize :price_cents

  scope :by_date, -> { order('created_at') }
  scope :by_name, -> { order('name') }

  MAX_DEBT = -80

  def subtract(shipping, payer)
    users.each do |user|
      user.subtract(price /
                    user_dishes_count +
                    shipping /
                    order.user_appearances_in_order[user.id], payer)
    end
  end
end
