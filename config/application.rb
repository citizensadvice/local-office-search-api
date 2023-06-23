# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LocalOfficeSearchApi
  class Application < Rails::Application
    # this is just an API application
    config.api_only = true

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # We use some Postgres features that Rails doesn't quite know about
    # so use the SQL dumping format
    config.active_record.schema_format = :sql

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # The location of the LSS data to be loaded
    config.lss_data_bucket = ENV.fetch("LSS_DATA_BUCKET", nil)

    # Set tags for logs, including Datadog trace info
    # This needs to be set here because the logger is already initialized by the
    # time we get to the initializers
    ci_test = ENV.fetch("CI_TEST", false)

    unless $stdout.tty? || ci_test
      config.log_tags = {
        request_id: :request_id,
        dd: lambda { |_|
          correlation = Datadog::Tracing.correlation
          {
            trace_id: correlation.trace_id.to_s,
            span_id: correlation.span_id.to_s,
            env: correlation.env.to_s,
            service: correlation.service.to_s,
            version: correlation.version.to_s
          }
        },
        ddsource: ["ruby"]
      }
    end
  end
end
