# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DishSerializer do
  let(:dish) { create(:dish, order: build(:order)) }
  let!(:user_dish) { create :user_dish, user: build(:user), dish: dish }
  let(:user) { dish.users.first }
  let(:current_user) { user }
  subject do
    described_class.new(dish, scope: current_user, scope_name: :current_user)
  end

  describe '#price' do
    it { expect(subject.price).to eq('13.30') }
  end

  describe '#user_name' do
    it 'delegates to user' do
      expect(subject.scope.name).to eq('Bartek Szef')
    end
  end

  context 'with policy' do
    context 'update allowed' do
      include_context 'allows_policy_action', DishPolicy, :update?
      it { expect(subject.editable).to be_truthy }
    end # context 'update allowed'

    context 'destroy allowed' do
      include_context 'allows_policy_action', DishPolicy, :destroy?
      it { expect(subject.deletable).to be_truthy }
    end # context 'destroy allowed'

    context 'copy allowed' do
      include_context 'allows_policy_action', DishPolicy, :copy?
      it { expect(subject.copyable).to be_truthy }
    end # context 'copy allowed'
  end

  describe '#belongs_to_current_user' do
    it 'returns true' do
      expect(subject.belongs_to_current_user).to be_truthy
    end

    context 'different current user' do
      let(:current_user) { create(:other_user) }

      it 'returns false' do
        expect(subject.belongs_to_current_user).to be_falsey
      end
    end # context 'different current user'
  end # describe '#belongs_to_current_user'

  describe '#from_today' do
    it 'return true' do
      expect(subject.from_today).to be_truthy
    end
  end # describe '#from_today'
end # RSpec.describe DishSerializer
