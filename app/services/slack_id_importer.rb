class SlackIdImporter
  def initialize(user)
    @user = user
  end

  def perform
    if @user.slack_id == nil
      url = "https://slack.com/api/users.lookupByEmail?email=#{@user.email}&token=#{ENV['SLACK_OAUTH_TOKEN']}"
      uri = URI(url)
      response = Net::HTTP.get(uri)
      output = JSON.parse(response)
      @user.update(slack_id: output['user']['id'])
    end
  end
end
