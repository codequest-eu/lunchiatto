# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BalanceQuery do
  let!(:company) { create :company }
  let!(:user) { create :user, company: company } 
  let!(:other_user) { create :other_user, company: company }
  let!(:order) { create :order, :with_ordered_status, user: user, 
                                                      company: company,
                                                      shipping: '7.00' }
  let!(:dish) { create :dish, order: order, price: '20.00' }
  let!(:user_dish) { create :user_dish, user: user, dish: dish }
  let!(:other_dish) { create :dish, order: order, price: '25.00' }
  let!(:other_user_dish) { create :user_dish, user: other_user, dish: other_dish }
  
  describe 'pending_balances' do    
    subject { described_class.new(user).pending_balances }
    
    it 'return correct pending balances towards specific user' do
      expect(subject[other_user.id].to_i)
        .to eq(other_dish.price_cents +
          order.shipping_cents/order.ordering_users_count)
    end
    
    context 'after order changes status to "delivered"' do
      before do
        order.change_status('delivered')
        order.save
      end
      
      it 'resets pending_balance' do
        expect(subject[other_user.id]).to eq(nil)
      end
      
      it "updates total_debt's" do
        expect(user.total_debt).to eq(0)
        expect(-other_user.total_debt.cents)
          .to eq(other_dish.price_cents +
            order.shipping_cents/order.ordering_users_count)
      end
    end
  
    context 'when dishes are shared' do
      let!(:another_user) { create :user, company: company }
      let!(:another_user_dish) { create :user_dish, dish: dish, user: another_user }
      
      it 'returns correct pending_balances' do
        expect(subject[another_user.id].to_i)
          .to eq(dish.price_cents/dish.user_dishes_count +
            order.shipping_cents/order.ordering_users_count)
      end
    end
  end
end
