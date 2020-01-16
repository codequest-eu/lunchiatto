# frozen_string_literal: true
class SlackIdImportWorker
  include Sidekiq::Worker

  def perform
    User.all.active.each do |user|
      SlackIdImporter.new(user).perform
    end
  end
end
