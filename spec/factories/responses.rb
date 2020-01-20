# frozen_string_literal: true
FactoryGirl.define do
  factory :response, class: Hash do
    skip_create
    ok true
    user { build(:response_user) }
    initialize_with { attributes.stringify_keys }
  end

  factory :response_user, class: Hash do
    skip_create
    id 'SLACKUSERID'
    initialize_with { attributes.stringify_keys }
  end
end
