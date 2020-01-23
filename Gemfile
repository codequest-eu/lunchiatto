# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails'
gem 'pg'
gem 'slim-rails'
gem 'active_model_serializers'
gem 'gon'

gem 'jquery-rails'
gem 'sass-rails'
gem 'compass-rails'
gem 'uglifier'
gem 'coffee-rails'

gem 'devise'

gem 'factory_girl_rails', '~> 4.0'

gem 'omniauth', '1.3.1'
gem 'omniauth-google-oauth2', '0.6.0'

gem 'money-rails'
gem 'pundit'
gem 'codequest_pipes'

gem 'puma'
gem 'kaminari'
gem 'nokogiri'
gem 'premailer'
gem 'premailer-rails'
gem 'tilt-jade'

gem 'slack-notifier'

# error reporting
gem 'airbrake'

# doc
gem 'sdoc', '~> 0.4.0', group: :doc

# queues
gem 'sidekiq'
gem 'sidekiq-scheduler'
# sidekiq currently requires sintatra stuff from master
gem 'sinatra', github: 'sinatra/sinatra'
gem 'rack-protection', github: 'sinatra/rack-protection'

# logging
gem 'remote_syslog_logger'
gem 'multilogger', github: 'codequest-eu/multilogger'

source 'https://rails-assets.org' do
  gem 'rails-assets-foundation'
  gem 'rails-assets-marionette'
  gem 'rails-assets-humanize-plus'
  gem 'rails-assets-uri.js'
  gem 'rails-assets-moment'
  gem 'rails-assets-chosen'
end

group :development, :test do
  gem 'slim_lint'
  gem 'reek'
  gem 'scss_lint', require: false
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'faker', '~> 1.8.0', require: false
  gem 'inch'
  gem 'pry'
  gem 'dotenv-rails'
  gem 'webmock'
  gem 'capybara'
end

group :development do
  gem 'binding_of_caller', '0.7.2'
  gem 'did-you-mean'
  gem 'pry'
end

group :test do
  gem 'rake'
  gem 'shoulda-matchers', require: false
  gem 'shoulda-callback-matchers', require: false
  gem 'simplecov', require: false
  gem 'rails-controller-testing' # remove someday
end
