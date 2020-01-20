# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlackIdImporter do
  let(:user) { create :user }
  let(:response) { create :response }
  subject { described_class.new(user) }

  before(:each) do
    stub_request(:get, /slack.com/).to_return(body: response.to_json)
  end

  it 'updates user slack id' do
    puts response
    expect(user.slack_id).to eql(nil)
    subject.perform
    expect(user.slack_id).to eql('SLACKUSERID')
  end
end
