# frozen_string_literal: true
module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize Order
      orders = current_user
        .company
        .orders
        .newest_first
        .page(params[:page])
        .includes(:dishes)
      render json: orders, shallow: true
    end

    def create
      order = Order.new order_params.merge(
        date: Time.zone.today,
        company: current_user.company,
      )
      authorize order, :index?
      save_record order
    end

    def show
      order = find_order
      authorize order, :index?
      render json: order
    end

    def update
      order = find_order
      authorize order
      update_record order, order_params
    end

    def destroy
      order = find_order
      authorize order
      destroy_record order
    end

    def change_status
      order = find_order
      authorize order
      order.change_status(params[:status].to_sym)
      if order.save
        render json: order
      else
        render json: {errors: ['Operation not allowed']},
               status: :unprocessable_entity
      end
    end

    def latest
      orders = find_todays_orders
      authorize Order, :index?
      render json: orders, shallow: true
    end

    def history
      orders =
        current_user.company.orders.joins(dishes: :user_dishes).where(
          'orders.user_id = ? OR user_dishes.user_id = ?',
          current_user.id, current_user.id
        ).newest_first
      render json: orders, shallow: true
    end

    private

    def order_params
      params.permit(:user_id, :from, :shipping)
    end

    def find_order
      Order.find(params[:id])
    end

    def find_todays_orders
      current_user.company.orders.today
    end
  end
end
