# frozen_string_literal: true
class Order < ActiveRecord::Base
  belongs_to :user
  has_many :dishes, dependent: :destroy
  belongs_to :company

  validates :user, presence: true
  validates :from, presence: true,
                   uniqueness: {
                     scope: [:date, :company_id],
                     message: 'There already is an order from there today',
                   },
                   length: {maximum: 255}
  validates :company, presence: true

  scope :newest_first, -> { order(date: :desc, created_at: :desc) }
  scope :as_created, -> { order(created_at: :asc) }
  scope :today, -> { as_created.where(date: Time.zone.today) }

  register_currency :pln
  monetize :shipping_cents

  enum status: {
    in_progress: 0,
    ordered: 1,
    delivered: 2,
  }

  def amount
    dishes.inject(Money.new(0, 'PLN')) do |sum, dish|
      sum + dish.price
    end
  end

  # This method updates status if legal and
  # triggers price substraction of the order
  def change_status(new_status)
    return if delivered? || (new_status == :delivered && in_progress?)
    self.status = new_status
    subtract_price if delivered?
  end

  def subtract_price
    return if dishes_count == 0
    dishes.each do |dish|
      dish.subtract shipping / sum_users, user
    end
  end

  def from_today?
    date.today?
  end

  def sum_users
    dishes
      .joins(:user_dishes)
      .pluck('user_dishes.user_id')
      .uniq
      .count
  end

  def user_appearances_in_order
    dishes
      .joins(:user_dishes)
      .pluck('user_dishes.user_id')
      .group_by(&:itself)
      .transform_values(&:count)
  end
end
