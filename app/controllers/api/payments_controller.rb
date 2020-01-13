# frozen_string_literal: true

require 'active_model_serializers'

module Api
  class PaymentsController < ApplicationController
    before_action :authenticate_user!

    def create
      payment = current_user.received_payments.new(payment_params)
      save_record payment
    end

    private

    def payment_params
      params.permit(:payer_id, :balance)
    end
  end
end
