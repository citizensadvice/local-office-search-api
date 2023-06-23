# frozen_string_literal: true

require "lss_loader"
require "s3_loader"

desc "Sync database with data sources"
task sync_database: :environment do
  raise "LSS_DATA_BUCKET is not specified, unable to continue" if Rails.configuration.lss_data_bucket.nil?

  Rails.logger.info("Opening LSS data files from S3...")
  begin
    s3_loader = S3Loader.new
    account_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_locations_flat.csv"
    opening_hours_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_location_opening_hours_flat.csv"

    Rails.logger.info("Starting LSS data import...")
    lss_loader = LssLoader.new account_csv, opening_hours_csv
    lss_loader.load!
  ensure
    account_csv&.close
    opening_hours_csv&.close
  end

  Rails.logger.info("Done")
end
