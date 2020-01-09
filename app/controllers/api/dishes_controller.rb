# frozen_string_literal: true
module Api
  class DishesController < ApplicationController
    before_action :authenticate_user!

    def create
      order = find_order
      dish = order.dishes.build(dish_params)
      authorize dish
      save_record dish
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
      update_record dish, dish_params
    end

    def destroy
      dish = find_dish
      authorize dish
      destroy_record dish
    end

    def copy
      dish = find_dish
      authorize dish
      new_dish = dish.copy(current_user)
      save_record new_dish
    end

    private

    def find_order
      Order.find(params[:order_id])
    end

    def find_dish
      find_order.dishes.find(params[:id])
    end

    def dish_params
      params.permit(:user_id, :name, :price)
    end

    def user_not_authorized
      render json: user_not_authorized_error_message, status: :unauthorized
    end

    def user_not_authorized_error_message
      {error: {dish: {message: 'Debt too large', limit: Dish::MAX_DEBT}}}
    end
  end
end
