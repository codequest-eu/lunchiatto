# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Balance do
  context 'given two users' do
    let(:company) { create :company }
    let(:user_1) { create :user, company: company }
    let(:user_2) { create :other_user, company: company }
    let(:user_3) { create :another_user, company: company }

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

    context 'with pending orders' do
      let!(:order) { create :order, :with_ordered_status, user: user_2 }
      let!(:order_2) { create :order, :with_ordered_status, user: user_3 }
      let!(:order_3) { create :order, user: user_3 }
      let!(:dish) { create :dish, order: order }
      let!(:user_dish) { create :user_dish, user: user_1, dish: dish }

      it 'returns proper pending_debt' do
        expect(user_1.pending_debt).to eq(-dish.price)
        expect(user_2.pending_debt.to_s.to_i).to eq(0)
        expect(user_3.pending_debt.to_s.to_i).to eq(0)
      end

      context 'with multiple pending orders' do
        let!(:dish_2) { create :dish, order: order_2 }
        let!(:user_dish_2) { create :user_dish, user: user_1, dish: dish_2 }
        let!(:dish_3) { create :dish, order: order_3 }
        let!(:user_dish_3) { create :user_dish, user: user_1, dish: dish_3 }

        let!(:payment) do
          create :payment, user: user_2, payer: user_1, balance: dish.price
        end

        it 'returns proper pending_debt' do
          expect(user_1.pending_debt).to eq(-dish_2.price)
        end
      end

      context 'with paid pending debt' do
        let!(:payment) do
          create(:payment, user: user_2, payer: user_1, balance: dish.price)
        end

        it 'returns null pending debt' do
          expect(user_1.pending_debt.to_s.to_i).to eq(0)
        end
      end
    end
  end
end
