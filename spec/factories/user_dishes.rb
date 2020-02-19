# frozen_string_literal: true
FactoryGirl.define do
  factory :user_dish do
    user
    dish
    dish_owner true
  end
end
