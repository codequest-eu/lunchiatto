# frozen_string_literal: true
class SlackNotifierWorker
  include Sidekiq::Worker

  def perform
    User.all.active.each do |user|
      next if user.slack_id.blank? || user.total_debt.to_i > User::NOTIFIER_DEBT
      notifier = Slack::Notifier.new ENV['WEBHOOK_URL'],
                                     channel: "@#{user.slack_id}",
                                     username: 'Shamer'
      notifier.ping message(user)
    end
  end

  def message(user)
    "Your Lunchiatto debt: #{user.total_debt} PLN"
  end
end
