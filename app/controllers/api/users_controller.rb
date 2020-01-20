# frozen_string_literal: true
module Api
  class UsersController < ApplicationController
    before_action :authenticate_user!

    def index
      users = current_user.company.users_by_name
      render json: users, with_balance: true
    end

    def show
      user = find_user
      render json: user
    end

    def update
      user = current_user
      update_record user, user_params
    end

    def destroy
      user = find_user
      authorize user
      deactivate_user(user)
    end

    private

    def user_params
      params.permit(:subtract_from_self, :account_number)
    end

    def find_user
      User.find(params[:id])
    end

    def deactivate_user(user)
      user.update(
        active: false,
        name: user.name.split.first,
        email: SecureRandom.urlsafe_base64(10),
        account_number: SecureRandom.urlsafe_base64(10),
        company_admin: false,
        admin: false,
        provider: SecureRandom.urlsafe_base64(10),
        slack_id: nil
      )
    end
  end
end
