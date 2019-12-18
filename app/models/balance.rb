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
    Money.new(all_debts.sum { |_, debt| debt }, 'PLN')
  end

  # returns the current balance between user and other
  def balance_for(other_user)
    Money.new(all_balances[other_user.id], 'PLN')
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

  # rubocop:disable Metrics/AbcSize
  def payment_debts
    Payment
      .where(
        "(user_id = #{user.id} OR payer_id = #{user.id}) " \
        "AND user_id != payer_id"
      )
      .group(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END"
      )
      .having(
        "SUM(CASE WHEN user_id = #{user.id} THEN -balance_cents " \
        "WHEN payer_id = #{user.id} THEN balance_cents END) < 0"
      )
      .pluck(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END, " \
        "SUM(CASE WHEN user_id = #{user.id} THEN -balance_cents " \
        "WHEN payer_id = #{user.id} THEN balance_cents END)"
      ).to_h
  end

  def payment_balances
    Payment
      .where(
        "(user_id = #{user.id} OR payer_id = #{user.id}) " \
        "AND user_id != payer_id"
      )
      .group(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END"
      )
      .pluck(
        "CASE WHEN user_id = #{user.id} THEN payer_id " \
        "WHEN payer_id = #{user.id} THEN user_id END, " \
        "SUM(CASE WHEN user_id = #{user.id} THEN -balance_cents " \
        "WHEN payer_id = #{user.id} THEN balance_cents END)"
      )
      .to_h
  end
  # rubocop:enable Metrics/AbcSize

  def pending_transfers
    @pending_transfers ||=
      Transfer
        .where(from_id: user.id, status: :pending)
        .group('to_id')
        .pluck('to_id, SUM(amount_cents)')
        .to_h
  end

  def all_balances
    @all_balances ||=
      payment_balances
        .merge(pending_transfers) { |_, balance, transfer| balance + transfer }
  end

  def all_debts
    payment_debts
      .merge(pending_transfers) { |_, balance, transfer| balance + transfer }
      .select { |_, balance| balance < 0 }
  end

  def payments_as_beneficiary
    @payments_as_beneficiary ||= Payment.newest_first.where(user: user)
  end

  def payments_as_payer
    @payments_as_payer ||= Payment.newest_first.where(payer: user)
  end
end
