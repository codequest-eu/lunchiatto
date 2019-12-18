# frozen_string_literal: true
class User < ActiveRecord::Base
  has_many :orders

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

  devise :database_authenticatable,
         :rememberable,
         :trackable,
         :omniauthable,
         omniauth_providers: [:google_oauth2]

  delegate :total_debt, to: :balance

  def balances
    balance = Balance.new(self)
    company
      .users
      .map { |usr| balance.build_wrapper(usr) }
      .reject { |bal| bal.balance == 0 }
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

  private

  def balance
    @balance ||= Balance.new(self)
  end
end
