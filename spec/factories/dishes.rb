# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dish do
    name { Faker::Food.dish }
    price '13.30'
    order
  end
end
