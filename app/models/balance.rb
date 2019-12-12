# frozen_string_literal: true
class Balance
  include ActiveModel::Model

  Wrapper = Struct.new(:user, :balance, :created_at) do
    include ActiveModel::Serialization
  end

  def initialize(user)
    @user = user
  end

  # returns the total account debt for user
  def total_debt
    Money.new(creditors.sum { |user| balance_for(user) }, 'PLN')
  end

  # returns the current balance between user and other
  def balance_for(other_user)
    Money.new(
      payments_as_payer.where(user: other_user).sum(:balance_cents) -
      payments_as_beneficiary.where(payer: other_user).sum(:balance_cents) +
      transfers_as_payer.where(to_id: other_user.id).sum(:amount_cents),
      'PLN'
    )
  end

  # returns a list of all debts and credits for user and other
  def payments_for(_other_user)
    fail NotImplementedError
  end

  # rubocop:disable Metrics/MethodLength
  def build_wrapper(other_user)
    last_paid = payments_as_payer.where(user: other_user).first
    last_received = payments_as_beneficiary.where(payer: other_user).first
    created_at = [
      last_paid&.created_at || Time.new(0),
      last_received&.created_at || Time.new(0),
    ].max
    Wrapper.new(
      other_user,
      balance_for(other_user),
      created_at,
    )
  end

  private

  attr_reader :user

  def payments_as_beneficiary
    @payments_as_beneficiary ||= Payment.newest_first.where(user: user)
  end

  def payments_as_payer
    @payments_as_payer ||= Payment.newest_first.where(payer: user)
  end

  def transfers_as_payer
    @transfers_as_payer ||= Transfer.where(from_id: user.id, status: :pending)
  end

  def creditors
    payments_as_beneficiary
      .map(&:payer)
      .uniq
      .select { |user| balance_for(user) < 0 }
  end
end
