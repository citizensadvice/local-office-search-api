# frozen_string_literal: true

task check_database: :environment do
  puts "Running example rake task to check Jenkins config"

  db_version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")
  puts db_version
end
