# frozen_string_literal: true
module Api
  class DishesController < ApplicationController
    before_action :authenticate_user!

    def create
      order = find_order
      dish = order.dishes.build(dish_params)
      authorize dish
      save_dish dish
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
      update_dish dish, dish_params
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
      copy_dish new_dish
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

    def save_dish(model)
      if model.save
        generate_user_dishes(model)
        yield(model) if block_given?
        render json: model
      else
        render json: {errors: model.errors}, status: :unprocessable_entity
      end
    end

    def update_dish(model, dish_params)
      if model.update(dish_params)
        model.user_dishes.destroy_all
        generate_user_dishes(model)
        yield(model) if block_given?
        render json: model
      else
        render json: {errors: model.errors}, status: :unprocessable_entity
      end
    end

    def copy_dish(model)
      if model.save
        Dish.reset_counters(model.id, :user_dishes)
        UserDish.create!(dish: model, user: current_user, dish_owner: true)
        yield(model) if block_given?
        render json: model
      else
        render json: {errors: model.errors}, status: :unprocessable_entity
      end
    end
    
    def generate_user_dishes(model)
      UserDish.create!(dish: model, user: current_user, dish_owner: true)
      params[:user_ids].each do |user_id|
        UserDish.create!(dish: model, user_id: user_id)
      end
    end
  end
end
