class SlackNotifierWorker
  include Sidekiq::Worker

  def perform
    User.all.active.each do |user|
      if user.slack_id && user.total_debt.to_i < -30
        notifier =
          Slack::Notifier.new ENV['WEBHOOK_URL'],
          channel: "@#{user.slack_id}",
          username: "Shamer"
        notifier.ping message(user)
      end
    end
  end

  def message(user)
    "Your Lunchiatto debt: #{user.total_debt.to_s} PLN"
  end
end
