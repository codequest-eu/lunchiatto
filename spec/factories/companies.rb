# frozen_string_literal: true
FactoryGirl.define do
  factory :company do
    name { Faker::Company.name }
  end

  factory :other_company, class: Company do
    name 'The Other Company'
  end
end
