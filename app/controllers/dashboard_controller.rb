# frozen_string_literal: true
class DashboardController < ApplicationController
  layout 'single_page_app'

  before_action :authenticate_user!

  def index
    authorize :dashboard
    gon_user
    gon.push(users_for_select: users_for_select,
             notice: flash[:notice],
             alert: flash[:alert])
  end

  private

  def user_not_authorized(exception)
    if exception.message == 'must be logged in'
      redirect_to root_url
    else
      redirect_to new_company_url
    end
  end

  def users_for_select
    ActiveModel::Serializer::CollectionSerializer.new(
      current_user.company.users_by_name.active,
      each_serializer: UserForSelectSerializer,
      scope: current_user,
    )
  end
end
