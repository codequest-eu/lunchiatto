# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    name 'Bartek Szef'
    sequence :email do |n|
      "bartek#{n}@test.net"
    end
    password 'jacekjacek'
    factory :admin_user do
      company_admin true
    end
    slack_id nil
    active true
  end

  factory :other_user, class: User do
    name 'Kruszcz Puszcz'
    email 'krus@test.net'
    password 'password'
    slack_id nil
    active true
  end

  factory :yet_another_user, class: User do
    sequence(:email) { |n| "kruszczu#{n}@test.net" }
    sequence(:name) { |n| "kruszczu#{n}" }
    password 'password'
    slack_id nil
    active false
  end
end
