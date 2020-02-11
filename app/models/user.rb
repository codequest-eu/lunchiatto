# frozen_string_literal: true
class User < ActiveRecord::Base
  has_many :orders
  has_many :user_dishes
  has_many :dishes, through: :user_dishes

  # TODO(anyone): remove user_balances and balances_as_payer
  has_many :user_balances, dependent: :destroy
  has_many :balances_as_payer, class_name: 'UserBalance',
                               inverse_of: :payer,
                               foreign_key: :payer_id
  # ---

  has_many :received_payments, inverse_of: :user,
                               class_name: 'Payment',
                               foreign_key: 'user_id'
  has_many :submitted_transfers, inverse_of: :from,
                                 class_name: 'Transfer',
                                 foreign_key: :from_id
  has_many :received_transfers, inverse_of: :to,
                                class_name: 'Transfer',
                                foreign_key: :to_id
  belongs_to :company

  after_create :add_first_balance

  scope :by_name, -> { order 'name' }
  scope :admin, -> { where admin: true }
  scope :active, -> { where active: true }

  devise :database_authenticatable,
         :rememberable,
         :trackable,
         :omniauthable,
         omniauth_providers: [:google_oauth2]

  delegate :total_debt, :pending_debt, to: :balance

  NOTIFIER_DEBT = -30

  def balances
    balance = Balance.new(self)
    company
      .users
      .map { |usr| balance.build_wrapper(usr) }
      .reject { |bal| bal.balance == 0 && bal.pending_balance == 0 }
  end

  def pending_orders_count
    pending_user_orders_count + pending_user_dishes_count
  end

  def add_first_balance
    # TODO(janek): no need to double write here - remove with user_balances
    user_balances.create balance: 0, payer: self
  end

  def subtract(amount, payer)
    return if self == payer && !subtract_from_self
    user_balances.create(balance: payer_balance(payer) - amount, payer: payer)
    received_payments.create!(balance: amount, payer: payer)
  end

  def to_s
    name
  end

  def payer_balance(payer)
    balance.balance_for(payer)
  end

  def debt_to(user)
    balance.balance_for(user)
  end

  def pending_transfers_count
    received_transfers.pending.size
  end

  def company_users_by_name
    company&.users_by_name
  end

  def active_company_users_by_name
    company_users_by_name&.active
  end

  private

  def balance
    @balance ||= Balance.new(self)
  end

  def pending_user_dishes_count
    Dish
      .joins(:order, :user_dishes)
      .where(
        'orders.status = 1 AND orders.user_id != ? AND user_dishes.user_id = ?',
        id, id
      )
      .count
  end

  def pending_user_orders_count
    Order
      .ordered
      .joins(:dishes)
      .where('orders.user_id = ?', id)
      .count
  end
end
