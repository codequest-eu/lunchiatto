# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Balance do
  context 'given two users' do
    let(:user_1) { create(:user) }
    let(:user_2) { create(:other_user) }
    let(:user_3) { create(:yet_another_user) }

    shared_context 'pays_for' do |payer, user, amt|
      before do
        # rubocop:disable Lint/Eval
        create(
          :payment, user: eval(user), payer: eval(payer), balance: amt
        )
        # rubocop:enable Lint/Eval
      end
    end

    it '#balance_for returns 0 if users are equal' do
      expect(described_class.new(user_1).balance_for(user_1)).to eq(0)
    end

    context 'it is 0 for user_1' do
      subject { described_class.new(user_1) }

      it { expect(subject.total_debt).to eq(0) }
    end

    context 'it is 1 for user_2' do
      subject { described_class.new(user_2) }

      it { expect(subject.total_debt).to eq(0) }
    end

    context 'given one transaction' do
      2.times do
        include_context 'pays_for', 'user_2', 'user_1', Money.new(100, 'PLN')
      end
      subject { described_class.new(user_1) }

      it { expect(subject.total_debt).to eq(Money.new(-200, 'PLN')) }
      it { expect(subject.balance_for(user_2)).to eq(Money.new(-200, 'PLN')) }

      context 'for other user' do
        subject { described_class.new(user_2) }

        it { expect(subject.total_debt).to eq(Money.new(0, 'PLN')) }
        it { expect(subject.balance_for(user_1)).to eq(Money.new(200, 'PLN')) }
      end
    end

    context 'given two transactions with distinct payers' do
      2.times do
        include_context 'pays_for', 'user_2', 'user_1', Money.new(100, 'PLN')
      end
      include_context 'pays_for', 'user_1', 'user_2', Money.new(150, 'PLN')

      subject { described_class.new(user_1) }

      it { expect(subject.total_debt).to eq(Money.new(-50, 'PLN')) }
      it { expect(subject.balance_for(user_2)).to eq(Money.new(-50, 'PLN')) }

      context 'for other user' do
        subject { described_class.new(user_2) }

        it { expect(subject.total_debt).to eq(Money.new(0, 'PLN')) }
        it { expect(subject.balance_for(user_1)).to eq(Money.new(50, 'PLN')) }
      end
    end

    context 'given five transactions' do
      2.times do
        include_context 'pays_for', 'user_2', 'user_1', Money.new(100, 'PLN')
      end
      include_context 'pays_for', 'user_1', 'user_2', Money.new(150, 'PLN')
      include_context 'pays_for', 'user_3', 'user_1', Money.new(200, 'PLN')
      include_context 'pays_for', 'user_2', 'user_3', Money.new(75, 'PLN')

      context 'for user_1' do
        subject { described_class.new(user_1) }

        it { expect(subject.total_debt).to eq(Money.new(-250, 'PLN')) }
        it { expect(subject.balance_for(user_2)).to eq(Money.new(-50, 'PLN')) }
        it { expect(subject.balance_for(user_3)).to eq(Money.new(-200, 'PLN')) }
      end

      context 'for user_2' do
        subject { described_class.new(user_2) }

        it { expect(subject.total_debt).to eq(Money.new(0, 'PLN')) }
        it { expect(subject.balance_for(user_1)).to eq(Money.new(50, 'PLN')) }
        it { expect(subject.balance_for(user_3)).to eq(Money.new(75, 'PLN')) }
      end

      context 'for user_3' do
        subject { described_class.new(user_3) }

        it { expect(subject.total_debt).to eq(Money.new(-75, 'PLN')) }
        it { expect(subject.balance_for(user_1)).to eq(Money.new(200, 'PLN')) }
        it { expect(subject.balance_for(user_2)).to eq(Money.new(-75, 'PLN')) }
      end
    end
  end
end
