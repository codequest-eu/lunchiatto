# frozen_string_literal: true
class UserDish < ActiveRecord::Base
  belongs_to :user
  belongs_to :dish, counter_cache: true
end
