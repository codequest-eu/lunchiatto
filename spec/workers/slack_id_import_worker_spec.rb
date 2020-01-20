# frozen_string_literal: true
require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe SlackIdImportWorker, type: :worker do
  let(:time) { (Time.zone.today + 1.hours).to_datetime }
  let(:scheduled_job) { described_class.perform_at(time, 'Awesome', true) }

  context 'occurs weekly' do
    it 'occurs at expected time' do
      scheduled_job
      assert_equal true, described_class.jobs.last['jid'].include?(scheduled_job)
      expect(described_class).to have_enqueued_sidekiq_job('Awesome', true)
    end
  end
end
