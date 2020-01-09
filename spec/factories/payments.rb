# frozen_string_literal: true
FactoryGirl.define do
  factory :payment do
    balance { rand(0.1..99.9).round(2) }
  end
end
