# frozen_string_literal: true
module Api
  class DishesController < ApplicationController
    before_action :authenticate_user!
    before_action :validate_users_debts, only: [:create, :update]

    def create
      order = find_order
      dish = order.dishes.build(dish_params)
      authorize dish
      params[:user_ids].sort
      save_record(dish) do |this_dish|
        this_dish.user_dishes.destroy_all
        generate_user_dishes(this_dish)
      end
    rescue Pundit::NotAuthorizedError
      user_not_authorized
    end

    def show
      dish = find_dish
      authorize dish
      render json: dish
    end

    def update
      dish = find_dish
      authorize dish
      update_record(dish, dish_params) do |this_dish|
        this_user_id = this_dish.user_dishes.find_by(dish_owner: true).user_id
        if current_user.id == this_user_id
          this_dish.user_dishes.destroy_all
          generate_user_dishes(this_dish)
        end
      end
    end

    def destroy
      dish = find_dish
      authorize dish
      destroy_record dish
    end

    def copy
      dish = find_dish
      authorize dish
      new_dish = dish.dup
      save_record(new_dish) do |this_dish|
        Dish.reset_counters(this_dish.id, :user_dishes)
        UserDish.create!(dish: new_dish,
                         user: current_user,
                         dish_owner: true)
      end
    end

    private

    def find_order
      Order.find(params[:order_id])
    end

    def find_dish
      find_order.dishes.find(params[:id])
    end

    def dish_params
      params.permit(:name, :price, :user_ids)
    end

    def user_dish_params
      params.permit(:user_id, :dish_id)
    end

    def user_not_authorized
      render json: {error: {dish: {message: 'Debt too large',
                                   limit: Dish::MAX_DEBT}}},
             status: :unauthorized
    end

    def user_unprocessable_entity
      render json: {error: {dish: {message: 'Debt too large for some users',
                                   limit: Dish::MAX_DEBT}}},
             status: :unprocessable_entity
    end

    def generate_user_dishes(dish)
      dish.user_dishes.create!(
        [
          {user: current_user, dish_owner: true},
          *params[:user_ids]&.map { |user_id| {user_id: user_id} },
        ]
      )
    end

    def validate_users_debts
      users =
        User.where(id: params[:user_ids]).none? do |user|
          user.total_debt.to_i < Dish::MAX_DEBT
        end
      return if users

      user_unprocessable_entity
    end
  end
end
