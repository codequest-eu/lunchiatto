# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OrderSerializer do
  let(:company) { create :company }
  let(:user) { create :user, company: company }
  let(:order) { create :order, user: user, company: company }
  let(:current_user) { user }
  subject do
    described_class.new order, scope: current_user, scope_name: :current_user
  end
  let(:policy) { instance_double('OrderPolicy') }

  describe '#shipping' do
    it 'delegates shipping' do
      expect(order).to receive(:shipping).and_return(11)
      expect(subject.shipping).to eq('11')
    end
  end # describe '#shipping'

  describe '#total' do
    it 'returns adequate' do
      expect(order).to receive(:shipping).and_return(3)
      expect(order).to receive(:amount).and_return(7)
      expect(subject.total).to eq('10')
    end
  end # describe '#total'

  describe 'with policy' do
    before do
      allow(OrderPolicy).to receive(:new) { policy }
      allow(subject).to receive(:current_user) { user }
    end

    it '#editable' do
      expect(policy).to receive(:update?) { true }
      expect(subject.editable).to be_truthy
    end # it '#editable'

    it '#deletable' do
      expect(policy).to receive(:destroy?) { true }
      expect(subject.deletable).to be_truthy
    end # it '#deletable'
  end # describe 'with policy'

  describe '#current_user_ordered?' do
    it 'returns false when users differ' do
      expect(subject.current_user_ordered).to be_falsey
    end

    context 'with other user' do
      let!(:dish) { create(:dish, order: order) }
      let!(:user_dish) { create :user_dish, user: user, dish: dish }

      it 'returns true when users do not differ' do
        expect(subject.current_user_ordered).to be_truthy
      end
    end # context 'with other user'
  end # describe '#current_user_ordered?'

  describe '#ordered_by_current_user?' do
    it 'returns true when user is the orderer' do
      expect(subject.ordered_by_current_user).to be_truthy
    end

    context 'with other user' do
      let(:current_user) { create(:other_user) }
      it 'returns false otherwise' do
        expect(subject.ordered_by_current_user).to be_falsey
      end
    end # context 'with other user'
  end # describe '#ordered_by_current_user?'
end # RSpec.describe OrderSerializer
