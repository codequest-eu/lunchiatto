# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::DishesController, type: :controller do
  let(:company) { create(:company) }
  let(:user) { create :user, company: company }
  let(:other_user) { create :other_user, company: company }
  let(:order) { create :order, user: user, company: company }

  describe 'POST create' do
    describe 'json' do
      it 'rejects when not logged in' do
        post_create
        expect(response).to have_http_status(401)
      end
      it 'returns success' do
        sign_in user
        post_create
        expect(response).to have_http_status(:success)
      end
      it 'creates a dish' do
        sign_in user
        expect { post_create }.to change(Dish, :count).by(1)
      end
      it 'returns errors' do
        sign_in user
        post_create(name: nil)
        expect(response).to have_http_status(422)
      end
      it 'creates user_dishes' do
        sign_in user
        expect { post_create }.to change(UserDish, :count).by(1)
      end

      context '2 users share a dish' do
        it 'creates 2 user_dishes' do
          sign_in user
          post_create_shared
          expect { post_create_shared }.to change(UserDish, :count).by(2)
        end

        it 'returns success' do
          sign_in user
          post_create_shared
          expect(response).to have_http_status(:success)
        end
      end

      def post_create(name: 'Name')
        post :create, order_id: order.id,
                      user_id: user.id,
                      price_cents: 14,
                      name: name,
                      format: :json
      end

      def post_create_shared(name: 'Name')
        post :create, order_id: order.id,
                      user_id: user.id,
                      user_ids: [other_user.id],
                      price_cents: 14,
                      name: name,
                      format: :json
      end
    end
  end

  describe 'PUT update' do
    let!(:dish) { create :dish, order: order }
    let!(:user_dish) do
      create :user_dish, user: user,
                         dish: dish,
                         dish_owner: true
    end
    let!(:other_dish) { create :dish, order: order }
    let!(:other_user_dish) do
      create :user_dish, dish: other_dish,
                         user: other_user,
                         dish_owner: true
    end
    describe 'json' do
      it 'rejects when not logged in' do
        put_update(dish: dish)
        expect(response).to have_http_status(401)
      end
      it 'returns success' do
        sign_in user
        put_update(dish: dish)
        expect(response).to have_http_status(:success)
      end
      it 'returns errors' do
        sign_in user
        put_update(dish: dish, name: '')
        expect(response).to have_http_status(422)
      end
      it 'does not allow others to edit' do
        sign_in other_user
        put_update(dish: dish)
        expect(response).to have_http_status(:unauthorized)
      end
      it 'allows the orderer to edit once ordered' do
        order.ordered!
        sign_in user
        put_update(dish: other_dish, name: 'Fame in the game')
        expect(response).to have_http_status(200)
      end
      def put_update(dish:, name: 'Name')
        put :update, order_id: order.id,
                     id: dish.id,
                     user_id: user.id,
                     name: name,
                     price: 13,
                     format: :json
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:dish) { create :dish, order: order }
    let!(:user_dish) do
      create :user_dish, user: user,
                         dish: dish,
                         dish_owner: true
    end
    describe 'json' do
      it 'rejects when not logged in' do
        delete :destroy, order_id: order.id, id: dish.id, format: :json
        expect(response).to have_http_status(401)
      end
      it 'rejects request from a different user' do
        sign_in other_user
        delete :destroy, order_id: order.id, id: dish.id, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
      it 'decrements the dishes count' do
        sign_in user
        expect do
          delete :destroy, order_id: order.id, id: dish.id, format: :json
        end.to change(Dish, :count).by(-1)
      end
      it 'is success' do
        sign_in user
        delete :destroy, order_id: order.id, id: dish.id, format: :json
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'POST copy' do
    let(:other_user) { create(:other_user) }
    let!(:dish) { create :dish, order: order }
    let!(:user_dish) { create :user_dish, user: user, dish: dish }
    describe 'json' do
      it 'copies a new dish' do
        sign_in other_user
        expect { post_copy }.to change(Dish, :count).by(1)
      end
      it 'does copy a dish if a user already has a dish in that order' do
        sign_in user
        expect { post_copy }.to change(Dish, :count).by(1)
      end
      it 'rejects when not logged in' do
        post_copy
        expect(response).to have_http_status(401)
      end
      it 'creates new user_dish' do
        sign_in user
        expect { post_copy }.to change(UserDish, :count).by(1)
      end
      it 'has correct user_dishes_count' do
        sign_in user
        post_copy
        expect(Dish.last.user_dishes_count).to eq(1)
      end
      it 'has correct dish_owner' do
        sign_in other_user
        post_copy
        expect(Dish.last.users.count).to eq(1)
        expect(Dish.last.users.first).to eq(other_user)
        expect(Dish.last.user_dishes.first.dish_owner).to eq(true)
      end

      def post_copy
        post :copy, order_id: order.id, id: dish.id, format: :json
      end
    end
  end

  describe 'GET show' do
    let(:dish) { create :dish, order: order }
    let!(:user_dish) { create :user_dish, user: user, dish: dish }

    describe 'json' do
      it 'rejects when not logged in' do
        request_show
        expect(response).to have_http_status(401)
      end
      it 'returns success' do
        sign_in user
        request_show
        expect(response).to have_http_status(:success)
      end
      def request_show
        get :show, order_id: order.id, id: dish.id, format: :json
      end
    end
  end
end
