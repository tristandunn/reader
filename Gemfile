# frozen_string_literal: true

ruby   "4.0.9"
source "https://rubygems.org"

gem "base64",   "0.3.0"
gem "fiddle",   "1.1.8"
gem "gtk4",     "4.3.9"
gem "nokogiri", "1.19.4", require: false

group :development, :test do
  gem "rspec-core",         "3.13.6"
  gem "rspec-expectations", "3.13.5"
  gem "rspec-mocks",        "3.13.8"
end

group :development do
  gem "irb",                 "1.18.0"
  gem "rake",                "13.4.2"
  gem "rubocop",             "1.92.1", require: false
  gem "rubocop-performance", "1.27.0", require: false
  gem "rubocop-rake",        "0.7.1",  require: false
  gem "rubocop-rspec",       "3.10.2", require: false
  gem "rubocop-vibe",        "0.6.0",  require: false
  gem "yard-lint",           "1.13.0", require: false
end

group :test do
  gem "simplecov",         "1.3.2", require: false
  gem "simplecov-console", "0.9.5", require: false
end
