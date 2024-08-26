# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.4"

# Use PostgreSQL as the database for Active Record
gem "activerecord-postgis-adapter"
gem "pg", "~> 1.5"
gem "rgeo-geojson"

# We load data from S3
gem "aws-sdk-s3"

# use the time of day gem to represent opening times in the database
gem "tod"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# Monitoring
gem "ddtrace", "~> 1.23.3"
gem "rails_semantic_logger", "~> 4.17"
gem "yabeda-prometheus", "~> 0.9"
gem "yabeda-puma-plugin", "~> 0.7"
gem "yabeda-rails", "~> 0.9"

# Use Swagger to document our APIs
gem "rswag-api"
gem "rswag-ui"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  # use .env files for local overrides
  gem "dotenv-rails"

  # Use RSwag to assist in running tests
  gem "rswag-specs"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem "rspec-rails", "~> 6.1.4"

  gem "simplecov", require: false

  gem "citizens-advice-style", github: "citizensadvice/citizens-advice-style-ruby", tag: "v11.0.0"
  gem "rubocop", require: false
end
