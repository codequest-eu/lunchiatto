# frozen_string_literal: true
class UserDish < ActiveRecord::Base
  belongs_to :user
  belongs_to :dish, counter_cache: true

  def subtract_dish
    dish.subtract shipping / dishes_count, user
  end
end
