# frozen_string_literal: true

# Share a service name in order to group all integrations
service_name = ENV.fetch("DD_SERVICE", "local-office-search-api")
ci_test = ENV.fetch("CI_TEST", false)
SemanticLogger.application = service_name

# Disable datadog if stdout is a TTY because it probably means a user is running
# Rails in a terminal
unless $stdout.tty? || ci_test
  Datadog.configure do |c|
    c.service = service_name
    c.tracing.instrument :active_support, cache_service: service_name
    c.tracing.instrument(:aws, service_name:)
    c.tracing.instrument :httprb
    c.tracing.instrument :rails
    c.tracing.instrument :active_record, service_name: "local-office-search-db"
  end
end
