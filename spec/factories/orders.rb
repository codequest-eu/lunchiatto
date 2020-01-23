# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order do
    date Time.zone.today
    from { Faker::Company.name }
    user
    company

    trait :with_ordered_status do
      status :ordered
    end

    factory :past_order do
      sequence :date do |n|
        Time.zone.today - 2 * n.days
      end
    end
  end
end
