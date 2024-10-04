# frozen_string_literal: true

require "lss_loader"
require "postcode_loader"
require "s3_loader"

desc "Sync database with data sources"
task sync_database: :environment do
  s3_loader = S3Loader.new

  # raise "GEO_DATA_BUCKET is not specified, unable to continue" if Rails.configuration.geo_data_bucket.nil?
  # raise "GEO_DATA_POSTCODES_FILE is not specified, unable to continue" if Rails.configuration.geo_data_postcodes_file.nil?
  #
  # Rails.logger.info("Opening geodata files from S3...")
  # begin
  #   postcode_csv = s3_loader.object_as_io Rails.configuration.geo_data_bucket, Rails.configuration.geo_data_postcodes_file
  #
  #   Rails.logger.info("Starting postcode import...")
  #   postcode_loader = PostcodeLoader.new postcode_csv
  #   postcode_loader.load!
  # ensure
  #   postcode_csv&.close
  # end

  raise "LSS_DATA_BUCKET is not specified, unable to continue" if Rails.configuration.lss_data_bucket.nil?

  Rails.logger.info("Opening LSS data files from S3...")
  begin
    members_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "citizens_advice_members_flat.csv"
    advice_locations_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_locations_flat.csv"
    opening_hours_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_location_opening_hours_flat.csv"
    volunteer_roles_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_locations_volunteer_roles_tidy.csv"
    accessibility_info_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "advice_locations_accessibility_tidy.csv"
    local_authorities_csv = s3_loader.object_as_io Rails.configuration.lss_data_bucket, "local_authority_data_tidy.csv"

    Rails.logger.info("Starting LSS data import...")
    lss_loader = LssLoader::LssLoader.new(members_csv:, advice_locations_csv:, opening_hours_csv:, volunteer_roles_csv:,
                                          accessibility_info_csv:, local_authorities_csv:)
    lss_loader.load!
  ensure
    members_csv&.close
    advice_locations_csv&.close
    opening_hours_csv&.close
    volunteer_roles_csv&.close
    accessibility_info_csv&.close
  end

  Rails.logger.info("Done")
end
