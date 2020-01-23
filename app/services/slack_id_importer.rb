# frozen_string_literal: true
class SlackIdImporter
  def initialize(user)
    @user = user
  end

  SLACK_API_URL = 'https://slack.com/api/users.lookupByEmail?email='

  def perform
    if @user.slack_id.blank?
      url = "#{SLACK_API_URL}#{@user.email}&token=#{ENV['SLACK_OAUTH_TOKEN']}"
      uri = URI(url)
      response = Net::HTTP.get(uri)
      output = JSON.parse(response)
      @user.update(slack_id: output['user']['id'])
    end
  end
end
