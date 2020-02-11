# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Order, type: :model do
  it { should belong_to(:user) }
  it { should have_many(:dishes) }
  it { should belong_to(:company) }
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:from) }
  it { should validate_presence_of(:company) }
  it do
    should validate_uniqueness_of(:from)
      .with_message('There already is an order from there today')
      .scoped_to(:date, :company_id)
  end
  it { should validate_length_of(:from).is_at_most(255) }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:date) { Time.zone.today }

  subject { create(:order, user: user, company: company, date: date) }

  it 'has statuses' do
    expect(described_class.statuses)
      .to eq('in_progress' => 0, 'ordered' => 1, 'delivered' => 2)
  end

  describe 'scopes' do
    let!(:order) { create :order, user: user, company: company }
    let!(:order2) do
      create :order, user: user, from: 'Another Place', company: company
    end
    let!(:order3) do
      create :order, user: user, date: 1.day.ago, company: company
    end

    describe '.today' do
      it "shows today's orders" do
        expect(described_class.today).to eq([order, order2])
      end
    end # describe '.today'

    describe '.as_created' do
      it 'shows in creation order' do
        expect(described_class.as_created).to eq([order, order2, order3])
      end
    end # describe '.as_created'

    describe '.newest_first' do
      it 'shows newest first' do
        expect(described_class.newest_first).to eq([order2, order, order3])
      end
    end # describe '.newest_first'
  end # describe 'scopes'

  describe '#amount' do
    it 'returns 0 when no dishes' do
      expect(subject.amount).to eq(Money.new(0, 'PLN'))
    end

    it 'returns 15 when there is a dish' do
      order = described_class.new date: Time.zone.today
      dish = instance_double('Dish')
      expect(dish).to receive(:price).and_return(Money.new(15, 'PLN'))
      expect(order).to receive(:dishes).and_return([dish])
      expect(order.amount).to eq(Money.new(15, 'PLN'))
    end
  end # describe '#amount'

  describe '#change_status' do
    context 'when in progress' do
      it 'changes from in_progress to ordered' do
        subject.change_status(:ordered)
        expect(subject.ordered?).to be_truthy
      end

      it 'does not substract price' do
        expect(subject).not_to receive(:subtract_price)
        subject.change_status(:ordered)
      end

      it 'does not allow changing from in progress to delivered' do
        subject.change_status(:delivered)
        expect(subject.in_progress?).to be_truthy
      end
    end # context 'when in progress'

    context 'when ordered' do
      before { subject.ordered! }

      it 'changes to delivered' do
        subject.change_status(:delivered)
        expect(subject.delivered?).to be_truthy
      end

      it 'substracts price' do
        expect(subject).to receive(:subtract_price)
        subject.change_status(:delivered)
      end

      it 'changes to in_progress' do
        subject.change_status(:in_progress)
        expect(subject.in_progress?).to be_truthy
      end
    end # context 'when ordered'

    context 'when delivered' do
      before { subject.delivered! }

      it 'does not change to ordered' do
        subject.change_status(:ordered)
        expect(subject.delivered?).to be_truthy
      end

      it 'does not change to in_progress' do
        subject.change_status('in_progress')
        expect(subject.delivered?).to be_truthy
      end
    end # context 'when delivered'
  end # describe '#change_status'

  describe '#subtract_price' do
    before { subject.shipping = Money.new(2000, 'PLN') }
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }
    let!(:dish1) { create(:dish, order: subject) }
    let!(:user_dish1) { create :user_dish, user: user_1, dish: dish1 }
    let!(:dish2) { create(:dish, order: subject) }
    let!(:user_dish2) { create :user_dish, user: user_2, dish: dish2 }

    it 'creates 2 balances' do
      expect { subject.subtract_price }.to change { UserBalance.count }.by(2)
    end

    it 'creates 2 payments' do
      expect { subject.subtract_price }.to change(Payment, :count).by(2)
    end

    it 'directs debt towards payer' do
      subject.subtract_price
      # dishes are 13.30 each + 10.00 in shipping
      expect(user.total_debt).to eq(Money.new(0, 'PLN'))
      expect(user_1.total_debt).to eq(Money.new(-2330, 'PLN'))
      expect(user_2.total_debt).to eq(Money.new(-2330, 'PLN'))
    end
  end # describe '#subtract_price'

  describe '#from_today?' do
    context 'today' do
      it { expect(subject.from_today?).to be_truthy }
    end # context 'today'
    context 'yesteday' do
      let(:date) { Date.yesterday }

      it { expect(subject.from_today?).to be_falsey }
    end # context 'yesteday'
  end # describe '#from_today?'
end # RSpec.describe Order
